import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/fingerprint_injector.dart';
import 'package:pbrowser/services/proxy/proxy_health_check.dart';
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';
import 'package:pbrowser/services/proxy/geo_ip_service.dart';

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
  
  // State
  bool _isLoading = true;
  bool _isWebViewLoading = false;
  bool _isControllerInitialized = false;
  bool _isProxyHealthy = true;
  double _progress = 0.0;
  
  static const String _initialUrl = 'https://whoer.net/ip';
  static final platform = const MethodChannel('com.example.pbrowser/proxy');

  late InAppWebViewSettings _settings;
  late List<UserScript> _userScripts;

  @override
  void initState() {
    super.initState();
    _activeFingerprint = widget.profile.fingerprintConfig;
    
    // Setup Modem IP Rotation Monitor
    _modemRotator = ModemRotatorService(proxyConfig: widget.profile.proxyConfig);
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
         } catch(_) {}
      }
    } else if (status == ModemStatus.online) {
      // Connection restored, reload if safe
    }
  }

  // ========================================================================
  // ANDROID/IOS WEBVIEW INITIALIZATION WITH SESSION ISOLATION
  // ========================================================================
  
  Future<void> _initializeApp() async {
    // 1. Health Check proxy BEFORE exposing the WebView to prevent IP leaks
    final isHealthy = await ProxyHealthCheckService.isProxyHealthy(widget.profile.proxyConfig);
    if (!mounted) return;
    
    if (!isHealthy) {
      setState(() {
        _isLoading = false;
        _isProxyHealthy = false;
      });
      return; // HALT INITIALIZATION
    }

    // 2. Fetch Sandbox Context (GeoIP, Timezone) based on Proxy IP
    try {
      final geoData = await GeoIpService.fetchGeoData(widget.profile.proxyConfig);
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
              // Add intentional slight randomness to accuracy so it's not strictly 50
              accuracy: 45.0 + (DateTime.now().millisecond % 15.0),
            ),
          );
        });
        debugPrint('[Browser] Applied dynamic Geo-IP sync: ${geoData['timezone']} / $lang');
      }
    } catch (e) {
       debugPrint('[Browser] Failed to dynamically sync Geo-IP: $e');
    }

    // 3. Set the profile data directory suffix FIRST (Android API 28+)
    if (Platform.isAndroid) {
      try {
        final success = await platform.invokeMethod<bool>('setProfileDirectory', {
          'profileId': widget.profile.id,
        });
        debugPrint('[Browser] Profile directory sandboxing applied: $success');
      } catch (e) {
        debugPrint('[Browser] Failed to isolate profile directory: $e');
      }
    }

    // 4. Set Proxy configuration (enforcing scheme for DNS resolution)
    await _setAndroidProxy();

    // 5. Setup native InAppWebViewSettings
    _settings = InAppWebViewSettings(
        userAgent: _activeFingerprint.userAgent,
        javaScriptEnabled: true,
        transparentBackground: false,
        clearCache: true, // as androidController.clearCache()
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
        forMainFrameOnly: false, // Applies to ALL IFRAMES - Fixes Iframe context leak!
      )
    ];

    // Controller is ready. Trigger UI rebuild to show InAppWebView
    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _setAndroidProxy() async {
    try {
      if (Platform.isAndroid && widget.profile.proxyConfig.isConfigured) {
        await platform.invokeMethod('setProxy', {
          'host': widget.profile.proxyConfig.host,
          'port': widget.profile.proxyConfig.port,
          'scheme': widget.profile.proxyConfig.type.toString(), // Enforces socks5:// to prevent DNS leaks
        });
      }
    } catch (e) {
      debugPrint('[Browser] Android proxy error: $e');
    }
  }

  // ========================================================================
  // NAVIGATION METHODS
  // ========================================================================
  
  void _loadUrl() {
    if (!_isProxyHealthy || _modemRotator.statusNotifier.value == ModemStatus.rotating) return;
    
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    
    // Android/iOS only
    _mobileController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ========================================================================
  // NATIVE TOUCH INJECTION
  // ========================================================================
  
  void _injectNativeTouch(double x, double y) {
    if (Platform.isAndroid) {
        try {
            platform.invokeMethod('injectTouch', {'x': x, 'y': y});
            debugPrint('[Browser] Injected Native Touch at: $x, $y');
        } catch(e) {
            debugPrint('[Browser] Failed to inject touch: $e');
        }
    }
  }

  // ========================================================================
  // UI BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
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
                    hintText: "Enter URL",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.shield_outlined, size: 16, color: Colors.green),
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
          // WebView - Android/iOS only
          if (_isControllerInitialized && _isProxyHealthy)
            GestureDetector(
                behavior: HitTestBehavior.opaque,
                // We don't block taps, we let them pass through but also send Native Touch
                onTapDown: (details) {
                    _injectNativeTouch(details.globalPosition.dx, details.globalPosition.dy);
                },
                child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_initialUrl)),
                    initialSettings: _settings,
                    initialUserScripts: UnmodifiableListView<UserScript>(_userScripts),
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
                        final platformLower = _activeFingerprint.platform.toLowerCase();
                        if (platformLower.contains('win')) osType = 'WINDOWS';
                        if (platformLower.contains('mac') || platformLower.contains('iphone') || platformLower.contains('ipad')) osType = 'MAC';
                        
                        final contextUsername = '${widget.profile.proxyConfig.username!}__OS_$osType';

                        return HttpAuthResponse(
                            action: HttpAuthResponseAction.PROCEED,
                            username: contextUsername,
                            password: widget.profile.proxyConfig.password!,
                        );
                      }
                      return HttpAuthResponse(action: HttpAuthResponseAction.CANCEL);
                    },
                    shouldInterceptRequest: (controller, request) async {
                        if (_modemRotator.statusNotifier.value != ModemStatus.online && _modemRotator.statusNotifier.value != ModemStatus.offline) {
                            // Block requests if rotating
                            return WebResourceResponse(statusCode: 403, reasonPhrase: 'Proxy Rotating', data: Uint8List(0));
                        }
                        
                        // We could modify headers here by performing DART http request 
                        // but it's slow. We rely on Fetch interception + App level User-Agent
                        return null; 
                    },
                    shouldInterceptFetchRequest: (controller, request) async {
                        // Dynamically override headers for Fetch (Client Hints)
                        request.headers ??= {};
                        request.headers!['User-Agent'] = _activeFingerprint.userAgent;
                        if (_activeFingerprint.secChUa.isNotEmpty) {
                            request.headers!['Sec-CH-UA'] = _activeFingerprint.secChUa;
                            request.headers!['Sec-CH-UA-Mobile'] = _activeFingerprint.platform.toLowerCase().contains('android') ? '?1' : '?0';
                            request.headers!['Sec-CH-UA-Platform'] = '"${_activeFingerprint.platform}"';
                        }
                        return request;
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                        if (_modemRotator.statusNotifier.value != ModemStatus.online && _modemRotator.statusNotifier.value != ModemStatus.offline) {
                            return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                    },
                ),
            ),
          
          // Progress bar
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
            
          // Modem Status Banner
          ValueListenableBuilder<ModemStatus>(
            valueListenable: _modemRotator.statusNotifier,
            builder: (context, status, child) {
              if (status == ModemStatus.online) return const SizedBox.shrink();
              
              return Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: status == ModemStatus.rotating ? Colors.orange : Colors.red,
                  child: Text(
                    status == ModemStatus.rotating 
                        ? 'Modem is rotating IP... Web traffic suspended to prevent leaks.'
                        : 'Modem connection lost.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          
          // Proxy Health Error Overlay
          if (!_isProxyHealthy)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security_update_warning, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Proxy Connection Failed!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Initialization blocked to prevent original IP leak.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _isProxyHealthy = true;
                        });
                        _initializeApp();
                      }, 
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection')
                    )
                  ],
                ),
              ),
            ),
          
          // Loading overlay
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
                      'Initializing ${widget.profile.name} (Verifying Proxy)...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
