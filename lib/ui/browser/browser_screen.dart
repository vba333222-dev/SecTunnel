import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/user_script.dart' as models;
import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/fingerprint/fingerprint_injector.dart';
import 'package:pbrowser/services/browser/cookie_manager_service.dart';
import 'package:pbrowser/services/browser/userscript_service.dart';

import 'package:pbrowser/services/proxy/proxy_health_check.dart';
import 'package:pbrowser/services/proxy/geo_ip_service.dart';
import 'package:pbrowser/services/proxy/mobile_proxy_service.dart';
import 'package:pbrowser/repositories/profile_repository.dart';

import 'package:provider/provider.dart';

// WebView imports
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pbrowser/ui/shared/themed_lottie.dart';

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
  static final Map<int, InAppWebViewController> _activeProxyConnections = {};

  // Controllers
  InAppWebViewController? _mobileController;
  final TextEditingController _urlController = TextEditingController();

  // Services
  late FingerprintConfig _activeFingerprint;

  // ── Browser state ───────────────────────────────
  bool _isLoading = true;
  bool _isWebViewLoading = false;
  bool _isControllerInitialized = false;
  bool _isProxyHealthy = true;
  double _progress = 0.0;
  List<models.UserScript> _activeScripts = [];

  // ── HUD state ───────────────────────────────────
  String? _currentPublicIp;
  bool _isIpFetching = false;
  bool _isRotating = false;
  bool _hudExpanded = false;
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
  WebViewEnvironment? _environment;
  late List<UserScript> _userScripts;

  // Whether this profile uses a proxy at all (determines HUD visibility)
  bool get _hasProxy => widget.profile.proxyConfig.type != ProxyType.none;

  @override
  void initState() {
    super.initState();
    _activeFingerprint = widget.profile.fingerprintConfig;

    // Start async initialization before creating the WebView
    _initializeApp();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _activeScripts.clear();
    
    final userDataFolder = widget.profile.userDataFolder;
    final profileId = widget.profile.id;
    final proxyPort = widget.profile.proxyConfig.port;

    if (proxyPort != null) {
      _activeProxyConnections.remove(proxyPort);
    }

    try {
      // Force all RAM cookies to physical isolated directory natively
      platform.invokeMethod('flushCookies').whenComplete(() {
        // Explictly save session state securely to SQLite in the background
        if (Platform.isAndroid) {
          CookieManagerService.exportCookies(profileId).then((cookies) {
            CookieManagerService.saveSessionToDb(userDataFolder, cookies);
          }).catchError((e) {
            debugPrint('[Browser] Background session cookie export failed: $e');
          });
        }
      });
    } catch (_) {}

    // Explicitly destroy WebView context to prevent OOM memory leaks
    if (_mobileController != null) {
      try {
        _mobileController!.loadUrl(
            urlRequest: URLRequest(url: WebUri('about:blank')));
        InAppWebViewController.clearAllCache();
        _mobileController!.dispose();
      } catch (e) {
        debugPrint('[Browser] Error during WebView dispose cleanup: $e');
      }
      _mobileController = null;
    }
    
    super.dispose();
  }

  // =========================================================================
  // ANDROID/IOS WEBVIEW INITIALIZATION WITH SESSION ISOLATION
  // =========================================================================

  Future<void> _initializeApp() async {
    final proxyPort = widget.profile.proxyConfig.port;
    if (proxyPort != null && _activeProxyConnections.containsKey(proxyPort)) {
       debugPrint('[Browser] Neutralizing ghost WebView instance occupying Port $proxyPort');
       try {
         final ghost = _activeProxyConnections[proxyPort];
         ghost?.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
         ghost?.dispose();
       } catch(_) {}
       _activeProxyConnections.remove(proxyPort);
    }

    if (mounted) {
      final userScriptService = Provider.of<UserScriptService>(context, listen: false);
      _activeScripts = await userScriptService.getActiveScripts(widget.profile.id);
    }

    // 1. Health Check proxy BEFORE exposing the WebView to prevent IP leaks
    final preFlight = await ProxyHealthCheckService.runPreFlightCheck(
        widget.profile.proxyConfig);
    if (!mounted) return;

    if (!preFlight.isHealthy) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) _showProxyFailureSheet(preFlight.errorReason);
      return; 
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
          _currentPublicIp = null;
        });
      }
    } catch (e) {
      debugPrint('[Browser] Failed to dynamically sync Geo-IP: $e');
    }

    // 3. Set the profile data directory suffix FIRST
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod<bool>('setProfileDirectory',
            {'profileId': widget.profile.id});
      } catch (e) {
        debugPrint('[Browser] setProfileDirectory error: $e');
      }
    }

    // 4. Set Proxy configuration
    await _setAndroidProxy();

    // 5. Setup native InAppWebViewEnvironment and Settings
    try {
      _environment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: widget.profile.userDataFolder,
        ),
      );
    } catch (e) {
      debugPrint('[Browser] Failed to create WebViewEnvironment: $e');
    }

    // clearCache is only true when the profile has the one-shot wipe flag set.
    _settings = InAppWebViewSettings(
      userAgent: _activeFingerprint.userAgent,
      javaScriptEnabled: true,
      transparentBackground: false,
      clearCache: widget.profile.clearBrowsingData,
      useShouldInterceptRequest: true,
      useShouldInterceptFetchRequest: true,
      useShouldInterceptAjaxRequest: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      javaScriptCanOpenWindowsAutomatically: false,
      incognito: false,
    );

    // Prepare UserScripts for Anti-Detect mechanism
    final injector = FingerprintInjector(_activeFingerprint);
    _userScripts = injector.generateUserScripts();

    // Load cookies from SQLite DB securely
    try {
      final cookies = await CookieManagerService.loadSessionFromDb(widget.profile.userDataFolder);
      if (cookies.isNotEmpty) {
        final cookieManager = CookieManager.instance();
        for (final cookie in cookies) {
          await cookieManager.setCookie(
            url: WebUri("https://${cookie.domain}"),
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain,
            path: cookie.path,
          );
        }
        debugPrint('[Browser] Successfully injected ${cookies.length} session cookies from SQLite');
      }
    } catch (e) {
      debugPrint('[Browser] Error injecting SQLite session cookies: $e');
    }

    // Controller is ready. Trigger UI rebuild to show InAppWebView
    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
        _isLoading = false;
      });

      // If we just did a one-shot cache wipe, reset the flag so future opens
      // don't clear browsing data again.
      if (widget.profile.clearBrowsingData) {
        try {
          final repo = Provider.of<ProfileRepository>(context, listen: false);
          await repo.updateProfile(
            widget.profile.copyWith(clearBrowsingData: false),
          );
        } catch (e) {
          debugPrint('[Browser] Failed to reset clearBrowsingData flag: $e');
        }
      }
    }

    // Fetch the public IP for the HUD after init
    _fetchPublicIp();
  }

  Future<void> _setAndroidProxy() async {
    final proxyConfig = widget.profile.proxyConfig;

    // ── Engine-level proxy override (flutter_inappwebview v6 API) ────────────
    // ProxyController.setProxyOverride() is the ONLY way to route WebView
    // traffic through a proxy in v6. Without it the WebView ignores all
    // OS-level proxy settings and leaks the real device IP.
    //
    // ProxyRule URL format: "[scheme://]host[:port]"
    //   • HTTP proxy  → "http://host:port"
    //   • SOCKS5      → "socks5://host:port"
    // ─────────────────────────────────────────────────────────────────────────
    if (proxyConfig.isConfigured) {
      final scheme = proxyConfig.type == ProxyType.socks5 ? 'socks5' : 'http';
      final proxyUrl = '$scheme://${proxyConfig.host!}:${proxyConfig.port!}';

      try {
        await ProxyController.instance().setProxyOverride(
          settings: ProxySettings(
            proxyRules: [ProxyRule(url: proxyUrl)],
          ),
        );
        debugPrint('[Browser] ProxyController override set → $proxyUrl');
      } catch (e) {
        debugPrint('[Browser] ProxyController.setProxyOverride error: $e');
      }
    } else {
      // No proxy for this profile — clear any override left by a previous session.
      try {
        await ProxyController.instance().clearProxyOverride();
      } catch (_) {}
    }

    // ── Fallback: native MethodChannel for system-level WebView process ───────
    // Covers edge cases where the Chromium process is shared across WebViews.
    try {
      if (Platform.isAndroid && proxyConfig.isConfigured) {
        await platform.invokeMethod('setProxy', {
          'host': proxyConfig.host,
          'port': proxyConfig.port,
          'scheme': proxyConfig.type.toString(),
        });
      }
    } catch (e) {
      debugPrint('[Browser] Native setProxy MethodChannel error: $e');
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

      await MobileProxyService.rotateIp(rotationUrl);

      debugPrint('[HUD] Rotation API called. Waiting for IP assignment…');

      // Give the modem ~4 s to assign a new IP before re-checking
      await Future.delayed(const Duration(seconds: 4));
    } on ProxyRotationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  void _showProxyFailureSheet([String? errorReason]) {
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
        errorReason: errorReason,
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
    if (!_isProxyHealthy || _isRotating) {
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
      backgroundColor: Colors.black, // Immersive edge-to-edge
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
                webViewEnvironment: _environment,
                initialUrlRequest:
                    URLRequest(url: WebUri(_initialUrl)),
                initialSettings: _settings,
                initialUserScripts:
                    UnmodifiableListView<UserScript>(_userScripts),
                onWebViewCreated: (controller) {
                  _mobileController = controller;
                  final pPort = widget.profile.proxyConfig.port;
                  if (pPort != null) {
                    _activeProxyConnections[pPort] = controller;
                  }
                },
                onLoadStart: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _isWebViewLoading = true;
                      _urlController.text = url?.toString() ?? '';
                    });
                  }
                  final urlStr = url?.toString() ?? '';
                  for (final script in _activeScripts) {
                    if (script.runAt == 'document_start') {
                      try {
                        final regex = RegExp(script.urlPattern, caseSensitive: false);
                        if (regex.hasMatch(urlStr)) {
                          controller.evaluateJavascript(source: script.jsPayload);
                        }
                      } catch (e) {
                        debugPrint('[UserScripts] Error executing script: $e');
                      }
                    }
                  }
                },
                onLoadStop: (controller, url) async {
                  if (mounted) {
                    setState(() {
                      _isWebViewLoading = false;
                      _urlController.text = url?.toString() ?? '';
                    });
                  }
                  final urlStr = url?.toString() ?? '';
                  for (final script in _activeScripts) {
                    if (script.runAt == 'document_idle') {
                      try {
                        final regex = RegExp(script.urlPattern, caseSensitive: false);
                        if (regex.hasMatch(urlStr)) {
                          controller.evaluateJavascript(source: script.jsPayload);
                        }
                      } catch (e) {
                        debugPrint('[UserScripts] Error executing script: $e');
                      }
                    }
                  }
                },
                onProgressChanged: (controller, p) {
                  if (mounted) {
                    setState(() => _progress = p / 100);
                  }
                },
                onReceivedHttpAuthRequest: (controller, challenge) async {
                  if (challenge.isProxy) {
                    final proxyUsername = (widget.profile.proxyConfig.username?.isNotEmpty == true)
                        ? widget.profile.proxyConfig.username!
                        : 'admin';
                    final proxyPassword = (widget.profile.proxyConfig.password?.isNotEmpty == true)
                        ? widget.profile.proxyConfig.password!
                        : 'rotator123';
                    
                    debugPrint("[PROXY AUTH] Mengirim kredensial ke: ${challenge.protectionSpace.host}");
                    
                    return HttpAuthResponse(
                      username: proxyUsername,
                      password: proxyPassword,
                      action: HttpAuthResponseAction.PROCEED,
                    );
                  }
                  return HttpAuthResponse(action: HttpAuthResponseAction.CANCEL);
                },
                shouldInterceptRequest: (controller, request) async {
                  if (_isRotating) {
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
                  if (_isRotating) {
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
          if (_isRotating || !_isProxyHealthy)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: _isRotating
                    ? Colors.orange
                    : Colors.red,
                child: Text(
                  _isRotating
                      ? 'Modem is rotating IP… Web traffic suspended to prevent leaks.'
                      : 'Modem connection lost.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // ── Loading overlay ───────────────────────────────
          if (_isLoading && _isProxyHealthy && !_isControllerInitialized)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThemedLottie(
                      animation: LottieAnimation.connecting,
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Running Pre-Flight Security Checks...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // ── EDGE SWIPE TO GO BACK ────────────────────────
          if (_isControllerInitialized && _isProxyHealthy)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 24, // 24px invisible hit area on the left edge
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  // If swiped right with sufficient velocity
                  if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                    _mobileController?.goBack();
                  }
                },
                child: const SizedBox(width: 24),
              ),
            ),

          // ── DYNAMIC ISLAND HUD ────────────────────────────
          if (_hasProxy)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              top: _hudVisible ? MediaQuery.of(context).padding.top + 8 : -140,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _hudVisible ? 1.0 : 0.0,
                child: AbsorbPointer(
                  absorbing: !_hudVisible,
                  child: _DynamicIslandHud(
                    profileName: widget.profile.name,
                    urlController: _urlController,
                    isProxyHealthy: _isProxyHealthy,
                    isLoading: _isLoading || _isWebViewLoading, // Merge loading states
                    expanded: _hudExpanded,
                    proxyConfig: widget.profile.proxyConfig,
                    isOnline: _isProxyHealthy && !_isRotating,
                    publicIp: _currentPublicIp,
                    isIpFetching: _isIpFetching,
                    isRotating: _isRotating,
                    hasRotationUrl: (widget.profile.proxyConfig.rotationUrl ?? '').isNotEmpty,
                    onLoadUrl: _loadUrl,
                    onReload: () {
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
                    onToggleExpand: () => setState(() => _hudExpanded = !_hudExpanded),
                    onRotateIp: _rotateIpNow,
                    onRefreshIp: _fetchPublicIp,
                    onCopyIp: () {
                      if (_currentPublicIp != null) {
                        Clipboard.setData(ClipboardData(text: _currentPublicIp!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('IP copied to clipboard'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
//  DYNAMIC ISLAND HUD WIDGET
// =============================================================================

class _DynamicIslandHud extends StatelessWidget {
  final String profileName;
  final TextEditingController urlController;
  final bool isProxyHealthy;
  final bool isLoading;
  final bool expanded;
  final ProxyConfig proxyConfig;
  final bool isOnline;
  final String? publicIp;
  final bool isIpFetching;
  final bool isRotating;
  final bool hasRotationUrl;
  final VoidCallback onLoadUrl;
  final VoidCallback onReload;
  final VoidCallback onToggleExpand;
  final VoidCallback onRotateIp;
  final VoidCallback onRefreshIp;
  final VoidCallback onCopyIp;

  const _DynamicIslandHud({
    required this.profileName,
    required this.urlController,
    required this.isProxyHealthy,
    required this.isLoading,
    required this.expanded,
    required this.proxyConfig,
    required this.isOnline,
    required this.publicIp,
    required this.isIpFetching,
    required this.isRotating,
    required this.hasRotationUrl,
    required this.onLoadUrl,
    required this.onReload,
    required this.onToggleExpand,
    required this.onRotateIp,
    required this.onRefreshIp,
    required this.onCopyIp,
  });

  Color get _statusColor {
    if (isRotating) return Colors.orangeAccent;
    if (isOnline) return Colors.greenAccent;
    return Colors.redAccent;
  }

  String get _statusLabel {
    if (isRotating) return 'Rotating…';
    if (isOnline) return 'Proxy Active';
    return 'Offline';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main Island Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xE81A1C29), // Sleek, slightly translucent dark
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Tap area to expand proxy info
              InkWell(
                onTap: onToggleExpand,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      // Status Dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        profileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
              // URL Input
              Expanded(
                child: TextField(
                  controller: urlController,
                  enabled: isProxyHealthy,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'Search or enter URL',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  onSubmitted: (_) => onLoadUrl(),
                ),
              ),
              
              // Reload/Loading indicator
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.tealAccent,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                color: Colors.white70,
                splashRadius: 20,
                onPressed: isLoading ? null : onReload,
              ),
            ],
          ),
        ),
        
        // Expanded Panel for Proxy Info
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: expanded
              ? Container(
                  key: const ValueKey('expanded-panel'),
                  width: 260, // Fixed width drop down
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE8141620),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _expandedContent(),
                )
              : const SizedBox.shrink(key: ValueKey('collapsed-panel')),
        ),
      ],
    );
  }

  Widget _expandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Row(
            children: [
              Icon(Icons.router_outlined, size: 14, color: Colors.white.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Expanded(
                child: isIpFetching
                    ? SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: _statusColor),
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
              if (publicIp != null && !isIpFetching)
                GestureDetector(
                  onTap: onCopyIp,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.copy_rounded, size: 14, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
              GestureDetector(
                onTap: isIpFetching ? null : onRefreshIp,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: isIpFetching ? Colors.white12 : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RotateButton(
            isRotating: isRotating,
            enabled: hasRotationUrl && !isRotating,
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
                    const _LottieRotateShim()
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
  final String? errorReason;
  final bool hasRotationUrl;
  final VoidCallback onRotateIp;
  final VoidCallback onRetry;
  final VoidCallback onOpenWithoutProxy;

  const _ProxyFailureSheet({
    required this.profileName,
    this.errorReason,
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

                const SizedBox(height: 16),
                const Center(
                  child: ThemedLottie(
                    animation: LottieAnimation.connectionError,
                    width: 72,
                    height: 72,
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 16),

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
                  errorReason ?? 'Could not reach the proxy server. The modem may be '
                  'resetting or the credentials are incorrect. '
                  'What would you like to do?',
                  style: TextStyle(
                    color: errorReason != null ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.55),
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

class _LottieRotateShim extends StatelessWidget {
  const _LottieRotateShim();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8.0, left: 4.0),
      child: ThemedLottie(
        animation: LottieAnimation.networkLoading,
        width: 18,
        height: 18,
      ),
    );
  }
}
