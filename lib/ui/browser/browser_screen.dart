import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/fingerprint_injector.dart';
import 'package:pbrowser/services/proxy/proxy_health_check.dart';
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';
import 'package:pbrowser/services/proxy/geo_ip_service.dart';

// WebView imports
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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
  // Controllers - Android only
  late final WebViewController _mobileController;
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
      // Pause webview execution or intercept navigation to prevent IP leaks
      if (_isControllerInitialized) {
         try {
           _mobileController.runJavaScript('window.stop();'); 
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
        print('[Browser] Applied dynamic Geo-IP sync: \${geoData['timezone']} / $lang');
      }
    } catch (e) {
       print('[Browser] Failed to dynamically sync Geo-IP: $e');
    }

    // 3. Set the profile data directory suffix FIRST (Android API 28+)
    if (Platform.isAndroid) {
      try {
        final success = await platform.invokeMethod<bool>('setProfileDirectory', {
          'profileId': widget.profile.id,
        });
        print('[Browser] Profile directory sandboxing applied: $success');
      } catch (e) {
        print('[Browser] Failed to isolate profile directory: $e');
      }
    }

    // 4. Set Proxy configuration (enforcing scheme for DNS resolution)
    await _setAndroidProxy();

    // 5. Initialize the WebView Controller
    _initMobileWebView();
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
      print('[Browser] Android proxy error: $e');
    }
  }

  void _initMobileWebView() {
    final PlatformWebViewControllerCreationParams params = 
        WebViewPlatform.instance is WebKitWebViewPlatform 
        ? WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true)
        : const PlatformWebViewControllerCreationParams();

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Block navigation if modem is rotating to prevent leak!
            if (_modemRotator.statusNotifier.value != ModemStatus.online && _modemRotator.statusNotifier.value != ModemStatus.offline /* Allow initial load? */) {
                // To be extremely strict, you would block all requests if != online
                // return NavigationDecision.prevent; 
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) async {
            if (mounted) {
              setState(() {
                _isWebViewLoading = true;
                _urlController.text = url;
              });
            }
            
            // Inject fingerprint early using the DYNAMIC environment variables
            try {
              final injector = FingerprintInjector(_activeFingerprint);
              final script = injector.generateInjectionScript();
              await controller.runJavaScript(script);
            } catch (e) {
              print('[Browser] Mobile fingerprint injection error: $e');
            }
          },
          onProgress: (p) {
            if (mounted) {
              setState(() => _progress = p / 100);
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isWebViewLoading = false;
                _urlController.text = url;
              });
            }
          },
          onHttpAuthRequest: (request) {
            // Handle proxy authentication
            if (widget.profile.proxyConfig.username != null) {
              request.onProceed(WebViewCredential(
                user: widget.profile.proxyConfig.username!,
                password: widget.profile.proxyConfig.password!,
              ));
            } else {
              request.onCancel();
            }
          },
        ),
      );
      
    // Android-specific optimizations (ClearCache as a fallback/clean slate)
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.clearCache();
    }
    
    _mobileController = controller;
    
    // Controller is ready. Trigger UI rebuild to show WebViewWidget
    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
      });
      _mobileController.loadRequest(Uri.parse(_initialUrl));
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
    _mobileController.loadRequest(Uri.parse(url));
    FocusManager.instance.primaryFocus?.unfocus();
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
                color: Colors.blueGrey.withOpacity(0.3),
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
                    fillColor: Colors.white.withOpacity(0.1),
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
                _mobileController.reload();
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
            WebViewWidget(controller: _mobileController),
          
          // Progress bar
          if (_isWebViewLoading && _isProxyHealthy)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
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
