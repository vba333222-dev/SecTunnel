import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/fingerprint/fingerprint_injector.dart';
import 'package:pbrowser/services/proxy/proxy_health_check.dart';
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';
import 'package:pbrowser/services/proxy/geo_ip_service.dart';
import 'package:http/http.dart' as http;

// WebView imports
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserScreen extends StatefulWidget {
  final BrowserProfile profile;

  const BrowserScreen({
    super.key,
    required this.profile,
  });

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  // Controllers
  InAppWebViewController? _mobileController;
  final TextEditingController _urlController = TextEditingController();

  // Services
  late final ModemRotatorService _modemRotator;
  late FingerprintConfig _activeFingerprint;

  // ── Browser state ───────────────────────────────
  bool _isLoading = true;
  bool _isWebViewLoading = false;
  bool _isControllerInitialized = false;
  bool _isProxyHealthy = true;
  double _progress = 0.0;

  // ── HUD state ───────────────────────────────────
  String? _currentPublicIp;
  bool _isIpFetching = false;
  bool _isRotating = false;
  bool _hudExpanded = false;
  /// true = collapsed to a 48px semi-transparent bubble (50% opacity).
  bool _hudMinimized = false;
  /// Driven by onScrollChanged — false hides the HUD entirely.
  bool _hudVisible = true;
  /// Last known scroll-Y; used to detect scroll direction.
  int _lastScrollY = 0;
  /// Position of the HUD's top-left corner relative to Stack.
  /// Initialized lazily on first layout.
  Offset? _hudOffset;

  static const String _initialUrl = 'https://whoer.net/ip';
  static final platform = const MethodChannel('com.example.pbrowser/proxy');

  late InAppWebViewSettings _settings;
  late List<UserScript> _userScripts;

  // Whether this profile uses a proxy at all (determines HUD visibility)
  bool get _hasProxy => widget.profile.proxyConfig.type != ProxyType.none;

  @override
  void initState() {
    super.initState();
    _activeFingerprint = widget.profile.fingerprintConfig;

    // Setup Modem IP Rotation Monitor
    _modemRotator =
        ModemRotatorService(proxyConfig: widget.profile.proxyConfig);
    _modemRotator.statusNotifier.addListener(_onModemStatusChanged);
    _modemRotator.startMonitoring();

    // Start async initialization before creating the WebView
    _initializeApp();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modemRotator.dispose();
    super.dispose();
  }

  void _onModemStatusChanged() {
    if (!mounted) return;

    final status = _modemRotator.statusNotifier.value;
    if (status == ModemStatus.rotating || status == ModemStatus.offline) {
      if (_mobileController != null) {
        try {
          _mobileController!.evaluateJavascript(source: 'window.stop();');
        } catch (_) {}
      }
    } else if (status == ModemStatus.online) {
      // Connection restored — refresh public IP for HUD
      _fetchPublicIp();
    }
  }

  // =========================================================================
  // ANDROID/IOS WEBVIEW INITIALIZATION WITH SESSION ISOLATION
  // =========================================================================

  Future<void> _initializeApp() async {
    // 1. Health Check proxy BEFORE exposing the WebView to prevent IP leaks
    final isHealthy = await ProxyHealthCheckService.isProxyHealthy(
        widget.profile.proxyConfig);
    if (!mounted) return;

    if (!isHealthy) {
      // Stay on loading screen but show the actionable bottom sheet.
      // Keep _isLoading=false so the "Verifying Proxy" overlay hides.
      if (mounted) setState(() => _isLoading = false);
      if (mounted) _showProxyFailureSheet();
      return; // HALT INITIALIZATION
    }

    // 2. Fetch Sandbox Context (GeoIP, Timezone) based on Proxy IP
    try {
      final geoData =
          await GeoIpService.fetchGeoData(widget.profile.proxyConfig);
      if (geoData != null && mounted) {
        final countryCode = geoData['countryCode'] as String;
        final lang = GeoIpService.countryCodeToLanguage(countryCode);

        setState(() {
          _activeFingerprint = _activeFingerprint.copyWith(
            timezone: geoData['timezone'] as String,
            language: lang,
            geolocation: GeolocationConfig(
              latitude: geoData['latitude'] as double,
              longitude: geoData['longitude'] as double,
              accuracy: 45.0 + (DateTime.now().millisecond % 15.0),
            ),
          );
          // Also update HUD IP from this initial geo fetch
          _currentPublicIp = null; // will be fetched separately
        });
        debugPrint(
            '[Browser] Applied dynamic Geo-IP sync: ${geoData['timezone']} / $lang');
      }
    } catch (e) {
      debugPrint('[Browser] Failed to dynamically sync Geo-IP: $e');
    }

    // 3. Set the profile data directory suffix FIRST (Android API 28+)
    if (Platform.isAndroid) {
      try {
        final success = await platform.invokeMethod<bool>('setProfileDirectory',
            {'profileId': widget.profile.id});
        debugPrint(
            '[Browser] Profile directory sandboxing applied: $success');
      } catch (e) {
        debugPrint('[Browser] Failed to isolate profile directory: $e');
      }
    }

    // 4. Set Proxy configuration
    await _setAndroidProxy();

    // 5. Setup native InAppWebViewSettings
    _settings = InAppWebViewSettings(
      userAgent: _activeFingerprint.userAgent,
      javaScriptEnabled: true,
      transparentBackground: false,
      clearCache: true,
      useShouldInterceptRequest: true,
      useShouldInterceptFetchRequest: true,
      useShouldInterceptAjaxRequest: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
    );

    // Prepare UserScripts for Anti-Detect mechanism
    final injector = FingerprintInjector(_activeFingerprint);
    _userScripts = [
      UserScript(
        source: injector.generateInjectionScript(),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: false,
      )
    ];

    // Controller is ready. Trigger UI rebuild to show InAppWebView
    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
        _isLoading = false;
      });
    }

    // Fetch the public IP for the HUD after init
    _fetchPublicIp();
  }

  Future<void> _setAndroidProxy() async {
    try {
      if (Platform.isAndroid && widget.profile.proxyConfig.isConfigured) {
        await platform.invokeMethod('setProxy', {
          'host': widget.profile.proxyConfig.host,
          'port': widget.profile.proxyConfig.port,
          'scheme': widget.profile.proxyConfig.type.toString(),
        });
      }
    } catch (e) {
      debugPrint('[Browser] Android proxy error: $e');
    }
  }

  // =========================================================================
  // HUD METHODS
  // =========================================================================

  /// Fetches the current external IP through the active proxy.
  Future<void> _fetchPublicIp() async {
    if (!mounted || !_hasProxy) return;
    if (_isIpFetching) return;

    setState(() => _isIpFetching = true);
    try {
      final geoData =
          await GeoIpService.fetchGeoData(widget.profile.proxyConfig);
      if (!mounted) return;
      setState(() {
        if (geoData != null) {
          // ip-api.com returns the external IP in the 'query' field but we
          // use a lightweight endpoint. Fallback: derive from lat/lon label.
          _currentPublicIp = geoData['ip'] as String? ??
              '${(geoData['latitude'] as double).toStringAsFixed(4)}°, '
                  '${(geoData['longitude'] as double).toStringAsFixed(4)}°';
        } else {
          _currentPublicIp = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _currentPublicIp = null);
    } finally {
      if (mounted) setState(() => _isIpFetching = false);
    }
  }

  /// Calls the rotation URL then re-fetches the public IP after a short delay.
  Future<void> _rotateIpNow() async {
    final rotationUrl = widget.profile.proxyConfig.rotationUrl;
    if (rotationUrl == null || rotationUrl.isEmpty) return;
    if (_isRotating) return;

    setState(() => _isRotating = true);
    HapticFeedback.mediumImpact();

    try {
      // Suspend WebView traffic during rotation
      if (_mobileController != null) {
        try {
          await _mobileController!
              .evaluateJavascript(source: 'window.stop();');
        } catch (_) {}
      }

      await http.get(Uri.parse(rotationUrl)).timeout(
            const Duration(seconds: 10),
          );

      debugPrint('[HUD] Rotation API called. Waiting for IP assignment…');

      // Give the modem ~4 s to assign a new IP before re-checking
      await Future.delayed(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[HUD] Rotation API error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRotating = false);
        await _fetchPublicIp();
      }
    }
  }

  // ── Proxy failure sheet & bypass helpers ───────────────────────────────

  void _showProxyFailureSheet() {
    // Triple-pulse vibrate — alerts user to a critical connection failure
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 100), HapticFeedback.vibrate);
    Future.delayed(const Duration(milliseconds: 200), HapticFeedback.vibrate);
    final rotationUrl = widget.profile.proxyConfig.rotationUrl ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProxyFailureSheet(
        profileName: widget.profile.name,
        hasRotationUrl: rotationUrl.isNotEmpty,
        onRotateIp: () {
          Navigator.pop(context);
          _rotateAndRetry();
        },
        onRetry: () {
          Navigator.pop(context);
          setState(() => _isLoading = true);
          _initializeApp();
        },
        onOpenWithoutProxy: () {
          Navigator.pop(context);
          _bypassProxyAndLoad();
        },
      ),
    );
  }

  /// Rotates IP then retries proxy initialization after a short delay.
  Future<void> _rotateAndRetry() async {
    await _rotateIpNow();
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isProxyHealthy = true;
    });
    _initializeApp();
  }

  /// Bypasses the proxy health check and proceeds directly to load the browser.
  void _bypassProxyAndLoad() {
    setState(() {
      _isLoading = true;
      _isProxyHealthy = true;
    });
    _initializeApp();
  }

  // =========================================================================
  // NAVIGATION METHODS
  // =========================================================================

  void _loadUrl() {
    if (!_isProxyHealthy ||
        _modemRotator.statusNotifier.value == ModemStatus.rotating) {
      return;
    }

    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';

    _mobileController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // =========================================================================
  // NATIVE TOUCH INJECTION
  // =========================================================================

  void _injectNativeTouch(double x, double y) {
    if (Platform.isAndroid) {
      try {
        platform.invokeMethod('injectTouch', {'x': x, 'y': y});
        debugPrint('[Browser] Injected Native Touch at: $x, $y');
      } catch (e) {
        debugPrint('[Browser] Failed to inject touch: $e');
      }
    }
  }

  // =========================================================================
  // UI BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Default HUD position: bottom-right
    _hudOffset ??=
        Offset(screenSize.width - 76, screenSize.height - 160);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            // Profile indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.profile.name,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 12),

            // URL bar
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _urlController,
                  enabled: _isProxyHealthy,
                  decoration: InputDecoration(
                    hintText: 'Enter URL',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.shield_outlined,
                        size: 16, color: Colors.green),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => _loadUrl(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_isControllerInitialized && _isProxyHealthy) {
                _mobileController?.reload();
              } else if (!_isProxyHealthy) {
                setState(() {
                  _isLoading = true;
                  _isProxyHealthy = true;
                });
                _initializeApp();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── WebView ─────────────────────────────────────
          if (_isControllerInitialized && _isProxyHealthy)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _injectNativeTouch(
                    details.globalPosition.dx, details.globalPosition.dy);
              },
              child: InAppWebView(
                initialUrlRequest:
                    URLRequest(url: WebUri(_initialUrl)),
                initialSettings: _settings,
                initialUserScripts:
                    UnmodifiableListView<UserScript>(_userScripts),
                onWebViewCreated: (controller) {
                  _mobileController = controller;
                },
                onLoadStart: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _isWebViewLoading = true;
                      _urlController.text = url?.toString() ?? '';
                    });
                  }
                },
                onLoadStop: (controller, url) async {
                  if (mounted) {
                    setState(() {
                      _isWebViewLoading = false;
                      _urlController.text = url?.toString() ?? '';
                    });
                  }
                },
                onProgressChanged: (controller, p) {
                  if (mounted) {
                    setState(() => _progress = p / 100);
                  }
                },
                onReceivedHttpAuthRequest: (controller, challenge) async {
                  if (widget.profile.proxyConfig.username != null) {
                    String osType = 'LINUX';
                    final platformLower =
                        _activeFingerprint.platform.toLowerCase();
                    if (platformLower.contains('win')) { osType = 'WINDOWS'; }
                    if (platformLower.contains('mac') ||
                        platformLower.contains('iphone') ||
                        platformLower.contains('ipad')) { osType = 'MAC'; }

                    final contextUsername =
                        '${widget.profile.proxyConfig.username!}__OS_$osType';
                    return HttpAuthResponse(
                      action: HttpAuthResponseAction.PROCEED,
                      username: contextUsername,
                      password: widget.profile.proxyConfig.password!,
                    );
                  }
                  return HttpAuthResponse(
                      action: HttpAuthResponseAction.CANCEL);
                },
                shouldInterceptRequest: (controller, request) async {
                  if (_modemRotator.statusNotifier.value !=
                          ModemStatus.online &&
                      _modemRotator.statusNotifier.value !=
                          ModemStatus.offline) {
                    return WebResourceResponse(
                        statusCode: 403,
                        reasonPhrase: 'Proxy Rotating',
                        data: Uint8List(0));
                  }
                  return null;
                },
                shouldInterceptFetchRequest:
                    (controller, request) async {
                  request.headers ??= {};
                  request.headers!['User-Agent'] =
                      _activeFingerprint.userAgent;
                  if (_activeFingerprint.secChUa.isNotEmpty) {
                    request.headers!['Sec-CH-UA'] =
                        _activeFingerprint.secChUa;
                    request.headers!['Sec-CH-UA-Mobile'] =
                        _activeFingerprint.platform
                                .toLowerCase()
                                .contains('android')
                            ? '?1'
                            : '?0';
                    request.headers!['Sec-CH-UA-Platform'] =
                        '"${_activeFingerprint.platform}"';
                  }
                  return request;
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async {
                  if (_modemRotator.statusNotifier.value !=
                          ModemStatus.online &&
                      _modemRotator.statusNotifier.value !=
                          ModemStatus.offline) {
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                // ── Scroll-direction auto-hide ───────────────
                // Deadzone: hide after 20px down, restore after 10px up
                // to avoid flicker on micro-scrolls.
                onScrollChanged: (controller, x, y) {
                  if (!mounted) return;
                  final scrollingDown = y > _lastScrollY + 20;
                  final scrollingUp   = y < _lastScrollY - 10;
                  _lastScrollY = y;
                  if (scrollingDown && _hudVisible) {
                    setState(() => _hudVisible = false);
                  } else if (scrollingUp && !_hudVisible) {
                    setState(() => _hudVisible = true);
                  }
                },
              ),
            ),

          // ── Progress bar ─────────────────────────────────
          if (_isWebViewLoading && _isProxyHealthy)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                color: Colors.blueAccent,
              ),
            ),

          // ── Modem Status Banner ───────────────────────────
          ValueListenableBuilder<ModemStatus>(
            valueListenable: _modemRotator.statusNotifier,
            builder: (context, status, child) {
              if (status == ModemStatus.online) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: status == ModemStatus.rotating
                      ? Colors.orange
                      : Colors.red,
                  child: Text(
                    status == ModemStatus.rotating
                        ? 'Modem is rotating IP… Web traffic suspended to prevent leaks.'
                        : 'Modem connection lost.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),

          // ── Loading overlay ───────────────────────────────
          if (_isLoading && _isProxyHealthy && !_isControllerInitialized)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'Initializing ${widget.profile.name} (Verifying Proxy)…',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // ── FLOATING HUD ──────────────────────────────────
          if (_hasProxy)
            // AnimatedOpacity drives both auto-hide (opacity 0) and
            // minimized-bubble (opacity 0.5). AbsorbPointer prevents
            // accidental taps when HUD is invisible.
            AnimatedOpacity(
              opacity: !_hudVisible
                  ? 0.0
                  : (_hudMinimized ? 0.50 : 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: AbsorbPointer(
                absorbing: !_hudVisible,
                child: ValueListenableBuilder<ModemStatus>(
                  valueListenable: _modemRotator.statusNotifier,
                  builder: (context, modemStatus, _) {
                    return _FloatingHud(
                      offset: _hudOffset!,
                      expanded: _hudExpanded,
                      minimized: _hudMinimized,
                      proxyConfig: widget.profile.proxyConfig,
                      modemStatus: modemStatus,
                      publicIp: _currentPublicIp,
                      isIpFetching: _isIpFetching,
                      isRotating: _isRotating,
                      hasRotationUrl: (widget.profile.proxyConfig.rotationUrl ??
                              '')
                          .isNotEmpty,
                      onDragUpdate: (delta) {
                        setState(() {
                          final newOffset = _hudOffset! + delta;
                          final size = MediaQuery.of(context).size;
                          _hudOffset = Offset(
                            newOffset.dx.clamp(0, size.width - 64),
                            newOffset.dy.clamp(0, size.height - 64),
                          );
                        });
                      },
                      onToggleExpand: () =>
                          setState(() => _hudExpanded = !_hudExpanded),
                      onToggleMinimize: () => setState(() {
                        _hudMinimized = !_hudMinimized;
                        // Minimize collapses the panel too
                        if (_hudMinimized) _hudExpanded = false;
                      }),
                      onRotateIp: _rotateIpNow,
                      onRefreshIp: _fetchPublicIp,
                      onCopyIp: () {
                        if (_currentPublicIp != null) {
                          Clipboard.setData(
                              ClipboardData(text: _currentPublicIp!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('IP copied to clipboard'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
//  FLOATING HUD WIDGET
// =============================================================================

class _FloatingHud extends StatelessWidget {
  final Offset offset;
  final bool expanded;
  /// When true the HUD collapses to a 48px bubble; parent sets opacity to 0.50.
  final bool minimized;
  final ProxyConfig proxyConfig;
  final ModemStatus modemStatus;
  final String? publicIp;
  final bool isIpFetching;
  final bool isRotating;
  final bool hasRotationUrl;
  final void Function(Offset delta) onDragUpdate;
  final VoidCallback onToggleExpand;
  /// Long-press FAB → minimize bubble. Tap bubble → restore.
  final VoidCallback onToggleMinimize;
  final VoidCallback onRotateIp;
  final VoidCallback onRefreshIp;
  final VoidCallback onCopyIp;

  const _FloatingHud({
    required this.offset,
    required this.expanded,
    required this.minimized,
    required this.proxyConfig,
    required this.modemStatus,
    required this.publicIp,
    required this.isIpFetching,
    required this.isRotating,
    required this.hasRotationUrl,
    required this.onDragUpdate,
    required this.onToggleExpand,
    required this.onToggleMinimize,
    required this.onRotateIp,
    required this.onRefreshIp,
    required this.onCopyIp,
  });

  Color get _statusColor {
    switch (modemStatus) {
      case ModemStatus.online:
        return Colors.greenAccent;
      case ModemStatus.rotating:
        return Colors.orangeAccent;
      case ModemStatus.offline:
        return Colors.redAccent;
    }
  }

  String get _statusLabel {
    switch (modemStatus) {
      case ModemStatus.online:
        return 'Proxy Active';
      case ModemStatus.rotating:
        return 'Rotating…';
      case ModemStatus.offline:
        return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    // minimized → 48px bubble, no coloured glow (opacity set by parent)
    final double radius = expanded ? 18 : 26;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanUpdate: (d) => onDragUpdate(d.delta),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          width: minimized ? 48 : (expanded ? 220 : 52),
          height: minimized ? 48 : (expanded ? null : 52),
          decoration: BoxDecoration(
            color: minimized
                ? Colors.black.withValues(alpha: 0.60)
                : const Color(0xE8141620),
            borderRadius: BorderRadius.circular(
                minimized ? 24 : radius),
            border: Border.all(
              color: minimized
                  ? Colors.white.withValues(alpha: 0.2)
                  : _statusColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: minimized
                ? null // no glow in minimized mode — reduces visual noise
                : [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: minimized
                ? _minimizedBubble()
                : (expanded ? _expandedContent() : _collapsedFab()),
          ),
        ),
      ),
    );
  }


  // ── Minimized: 48px semi-transparent bubble ───────────────────────────

  Widget _minimizedBubble() {
    return Tooltip(
      message: 'Tap to restore HUD',
      child: InkWell(
        onTap: onToggleMinimize,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Icon(
            Icons.radar_rounded,
            size: 22,
            color: _statusColor.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  // ── Collapsed: FAB-like ────────────────────────────────────────────────

  Widget _collapsedFab() {
    return SizedBox(
      width: 52,
      height: 52,
      child: InkWell(
        onTap: onToggleExpand,
        // Long-press → minimize to bubble
        onLongPress: onToggleMinimize,
        borderRadius: BorderRadius.circular(26),
        child: Tooltip(
          message: 'Long-press to minimize',
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: modemStatus == ModemStatus.online ? 36 : 32,
                  height: modemStatus == ModemStatus.online ? 36 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor.withValues(alpha: 0.15),
                  ),
                ),
                // Core dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Expanded panel ─────────────────────────────────────────────────────

  Widget _expandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              // Collapse button
              GestureDetector(
                onTap: onToggleExpand,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.1)),
          ),

          // IP address row
          Row(
            children: [
              Icon(
                Icons.router_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: isIpFetching
                    ? SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _statusColor,
                        ),
                      )
                    : Text(
                        publicIp ?? '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              // Copy button
              if (publicIp != null && !isIpFetching)
                GestureDetector(
                  onTap: onCopyIp,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              // Refresh button
              GestureDetector(
                onTap: isIpFetching ? null : onRefreshIp,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: isIpFetching
                        ? Colors.white12
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Rotate IP button ──────────────────────────────
          _RotateButton(
            isRotating: isRotating,
            enabled: hasRotationUrl &&
                modemStatus != ModemStatus.rotating &&
                !isRotating,
            statusColor: _statusColor,
            onPressed: onRotateIp,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  ROTATE IP BUTTON (extracted for clarity)
// =============================================================================

class _RotateButton extends StatelessWidget {
  final bool isRotating;
  final bool enabled;
  final Color statusColor;
  final VoidCallback onPressed;

  const _RotateButton({
    required this.isRotating,
    required this.enabled,
    required this.statusColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [
                    Colors.deepOrange.shade700,
                    Colors.orange.shade600,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.white12,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRotating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Colors.white70),
                    )
                  else
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: enabled ? Colors.white : Colors.white24,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isRotating ? 'Rotating IP…' : 'Rotate IP Now',
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  PROXY FAILURE BOTTOM SHEET
// =============================================================================

class _ProxyFailureSheet extends StatelessWidget {
  final String profileName;
  final bool hasRotationUrl;
  final VoidCallback onRotateIp;
  final VoidCallback onRetry;
  final VoidCallback onOpenWithoutProxy;

  const _ProxyFailureSheet({
    required this.profileName,
    required this.hasRotationUrl,
    required this.onRotateIp,
    required this.onRetry,
    required this.onOpenWithoutProxy,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A28),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ─────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Header ───────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Proxy Connection Failed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profileName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  'Could not reach the proxy server. The modem may be '
                  'resetting or the credentials are incorrect. '
                  'What would you like to do?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                Divider(color: Colors.white.withValues(alpha: 0.08)),

                const SizedBox(height: 16),

                // ── Action tiles ─────────────────────────────
                if (hasRotationUrl) ...[
                  _ActionTile(
                    icon: Icons.swap_horiz_rounded,
                    iconColor: Colors.tealAccent,
                    bgColor: Colors.tealAccent.withValues(alpha: 0.10),
                    title: 'Rotate IP Now',
                    subtitle: 'Request a new IP from the modem, then retry',
                    onTap: onRotateIp,
                  ),
                  const SizedBox(height: 10),
                ],

                _ActionTile(
                  icon: Icons.refresh_rounded,
                  iconColor: Colors.purpleAccent,
                  bgColor: Colors.purpleAccent.withValues(alpha: 0.10),
                  title: 'Retry Connection',
                  subtitle: 'Re-check proxy health and reconnect',
                  onTap: onRetry,
                ),

                const SizedBox(height: 10),

                _ActionTile(
                  icon: Icons.public_rounded,
                  iconColor: Colors.amberAccent,
                  bgColor: Colors.amberAccent.withValues(alpha: 0.08),
                  title: 'Open Without Proxy',
                  subtitle: 'Browse using your real IP (anonymity reduced)',
                  onTap: onOpenWithoutProxy,
                  outlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outlined
                  ? iconColor.withValues(alpha: 0.35)
                  : iconColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: outlined
                      ? iconColor.withValues(alpha: 0.08)
                      : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: outlined ? iconColor : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
