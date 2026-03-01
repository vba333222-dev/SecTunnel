import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/user_script.dart';
import 'package:pbrowser/services/fingerprint/fingerprint_injector.dart';
import 'package:pbrowser/services/browser/cookie_manager_service.dart';
import 'package:pbrowser/services/browser/userscript_service.dart';
import 'package:provider/provider.dart';

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
  WebViewController? _mobileController;
  final TextEditingController _urlController = TextEditingController();
  
  // State
  bool _isLoading = true;
  bool _isWebViewLoading = false;
  double _progress = 0.0;
  bool _isControllerInitialized = false;
  
  List<UserScript> _activeScripts = [];
  
  static const String _initialUrl = 'https://whoer.net/ip';
  static final platform = const MethodChannel('com.example.pbrowser/proxy');

  @override
  void initState() {
    super.initState();
    // Android/iOS only
    _initMobileWebViewAsync();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _activeScripts.clear();
    
    // Explicitly destroy WebView context to prevent OOM memory leaks
    if (_mobileController != null) {
      try {
        _mobileController!.loadRequest(Uri.parse('about:blank'));
        _mobileController!.clearCache();
        _mobileController!.setNavigationDelegate(NavigationDelegate());
      } catch (e) {
        debugPrint('[Browser] Error during WebView dispose cleanup: $e');
      }
      _mobileController = null;
    }
    
    super.dispose();
  }

  // ========================================================================
  // ANDROID/IOS WEBVIEW INITIALIZATION WITH SESSION ISOLATION
  // ========================================================================
  
  Future<void> _setProfileDirectory() async {
    if (Platform.isAndroid && widget.profile.id.isNotEmpty) {
      try {
        await platform.invokeMethod('setProfileDirectory', {
          'profileId': widget.profile.id,
        });
      } on PlatformException catch (e) {
        debugPrint('[Browser] Failed to set profile directory: ${e.message}');
      }
    }
  }

  Future<void> _setAndroidProxy() async {
    try {
      if (Platform.isAndroid && widget.profile.proxyConfig.isConfigured) {
        await platform.invokeMethod('setProxy', {
          'host': widget.profile.proxyConfig.host,
          'port': widget.profile.proxyConfig.port,
        });
      }
    } catch (e) {
      debugPrint('[Browser] Android proxy error: $e');
    }
  }

  Future<void> _initMobileWebViewAsync() async {
    await _setProfileDirectory();
    await _setAndroidProxy();
    
    // Load active UserScripts for this profile
    if (mounted) {
      final userScriptService = Provider.of<UserScriptService>(context, listen: false);
      _activeScripts = await userScriptService.getActiveScripts(widget.profile.id);
    }

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
          onPageStarted: (url) async {
            if (mounted) {
              setState(() {
                _isWebViewLoading = true;
                _urlController.text = url;
              });
            }
            
            // Inject fingerprint early
            try {
              final injector = FingerprintInjector(widget.profile.fingerprintConfig);
              final script = injector.generateInjectionScript();
              await controller.runJavaScript(script);
            } catch (e) {
              debugPrint('[Browser] Mobile fingerprint injection error: $e');
            }

            // Run Document Start UserScripts
            for (final script in _activeScripts) {
              if (script.runAt == 'document_start') {
                try {
                  final regex = RegExp(script.urlPattern, caseSensitive: false);
                  if (regex.hasMatch(url)) {
                    await controller.runJavaScript(script.jsPayload);
                    debugPrint('[Browser] Injected document_start script: ${script.name}');
                  }
                } catch (e) {
                  debugPrint('[Browser] Regex/Script error for ${script.name}: $e');
                }
              }
            }
          },
          onProgress: (p) {
            if (mounted) {
              setState(() => _progress = p / 100);
            }
          },
          onPageFinished: (url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isWebViewLoading = false;
                _urlController.text = url;
              });
            }

            // Run Document Idle UserScripts
            for (final script in _activeScripts) {
              if (script.runAt == 'document_idle') {
                try {
                  final regex = RegExp(script.urlPattern, caseSensitive: false);
                  if (regex.hasMatch(url)) {
                    await controller.runJavaScript(script.jsPayload);
                    debugPrint('[Browser] Injected document_idle script: ${script.name}');
                  }
                } catch (e) {
                  debugPrint('[Browser] Regex/Script error for ${script.name}: $e');
                }
              }
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
      
    // Android-specific optimizations
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      
      // We still clear cache as fallback, but primary isolation is via data directory suffix
      androidController.clearCache();
    }
    
    _mobileController = controller;
    
    // Inject pending cookies before first request
    try {
      final pendingCookiesPath = CookieManagerService.getPendingCookiesPath(widget.profile.userDataFolder);
      final file = File(pendingCookiesPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = jsonDecode(content) as List;
        
        final cookieManager = WebViewCookieManager();
        
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            final cookie = CookieItem.fromJson(item);
            await cookieManager.setCookie(WebViewCookie(
              name: cookie.name,
              value: cookie.value,
              domain: cookie.domain,
              path: cookie.path,
            ));
          }
        }
        
        await file.delete();
        debugPrint('[Browser] Successfully injected pending cookies');
      }
    } catch (e) {
      debugPrint('[Browser] Error injecting pending cookies: $e');
    }
    
    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
      });
      _mobileController?.loadRequest(Uri.parse(_initialUrl));
    }
  }

  // ========================================================================
  // NAVIGATION METHODS
  // ========================================================================
  
  void _loadUrl() {
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    
    // Android/iOS only
    _mobileController?.loadRequest(Uri.parse(url));
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
              _mobileController?.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView - Android/iOS only
          if (_isControllerInitialized && _mobileController != null)
            WebViewWidget(controller: _mobileController!),
          
          // Progress bar
          if (_isWebViewLoading)
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
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'Initializing ${widget.profile.name}...',
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
