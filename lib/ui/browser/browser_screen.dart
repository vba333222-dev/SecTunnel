import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/services/proxy/windows_local_proxy.dart';
import 'package:pbrowser/services/fingerprint/fingerprint_injector.dart';

// WebView imports
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

// Windows FFI
import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';

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
  late final WebViewController _mobileController;
  final windows_webview.WebviewController _windowsController = windows_webview.WebviewController();
  final TextEditingController _urlController = TextEditingController();
  
  // Proxy
  WindowsLocalProxy? _windowsProxy;
  
  // State
  bool _isLoading = true;
  bool _isWebViewLoading = false;
  double _progress = 0.0;
  
  static const String _initialUrl = 'https://whoer.net/ip';
  static final platform = const MethodChannel('com.example.pbrowser/proxy');

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initWindowsWebView();
    } else {
      _initMobileWebView();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    if (Platform.isWindows) {
      _windowsController.dispose();
      _windowsProxy?.stop();
    }
    super.dispose();
  }

  // ========================================================================
  // WINDOWS WEBVIEW INITIALIZATION WITH SESSION ISOLATION
  // ========================================================================
  
  Future<void> _initWindowsWebView() async {
    try {
      // 1. Start local proxy if configured
      if (widget.profile.proxyConfig.isConfigured) {
        _windowsProxy = WindowsLocalProxy(
          proxyType: widget.profile.proxyConfig.type,
          upstreamHost: widget.profile.proxyConfig.host!,
          upstreamPort: widget.profile.proxyConfig.port!,
          username: widget.profile.proxyConfig.username,
          password: widget.profile.proxyConfig.password,
        );
        
        final localPort = await _windowsProxy!.start();
        if (localPort > 0) {
          _setWindowsProxyArgs(localPort);
        }
      }
      
      // 2. Initialize WebView with isolated user data folder
      // NOTE: userDataFolder parameter may require newer webview_windows version
      // For now, we initialize without it - implement via native platform if needed
      await _windowsController.initialize();
      
      // 3. Setup listeners
      _windowsController.url.listen((url) {
        if (mounted) {
          _urlController.text = url;
        }
      });
      
      _windowsController.loadingState.listen((state) async {
        if (mounted) {
          if (state == windows_webview.LoadingState.loading) {
            setState(() => _isWebViewLoading = true);
          } else if (state == windows_webview.LoadingState.navigationCompleted) {
            setState(() => _isWebViewLoading = false);
            
            // Inject fingerprint script after page load
            await _injectFingerprint();
          }
        }
      });
      
      // 4. Wait for initialization
      await Future.delayed(const Duration(seconds: 2));
      
      // 5. Load initial URL
      if (mounted) {
        setState(() => _isLoading = false);
        _urlController.text = _initialUrl;
        await _windowsController.loadUrl(_initialUrl);
      }
      
    } catch (e) {
      print('[Browser] Windows init error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Inject WebView2 proxy arguments via FFI
  void _setWindowsProxyArgs(int port) {
    if (!Platform.isWindows || port == 0) return;
    
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final setEnv = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16>, Pointer<Utf16>),
          int Function(Pointer<Utf16>, Pointer<Utf16>)
      >('SetEnvironmentVariableW');
      
      final name = 'WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS'.toNativeUtf16();
      final args = '--proxy-server=127.0.0.1:$port --disable-background-timer-throttling';
      final value = args.toNativeUtf16();
      
      setEnv(name, value);
      
      calloc.free(name);
      calloc.free(value);
      
      print('[Browser] Injected WebView2 proxy args: $args');
    } catch (e) {
      print('[Browser] FFI error: $e');
    }
  }
  
  /// Inject fingerprint spoofing script
  Future<void> _injectFingerprint() async {
    try {
      final injector = FingerprintInjector(widget.profile.fingerprintConfig);
      final script = injector.generateInjectionScript();
      
      await _windowsController.executeScript(script);
      print('[Browser] Fingerprint injected successfully');
    } catch (e) {
      print('[Browser] Fingerprint injection error: $e');
    }
  }

  // ========================================================================
  // ANDROID/IOS WEBVIEW INITIALIZATION WITH SESSION ISOLATION
  // ========================================================================
  
  Future<void> _setAndroidProxy() async {
    try {
      if (Platform.isAndroid && widget.profile.proxyConfig.isConfigured) {
        await platform.invokeMethod('setProxy', {
          'host': widget.profile.proxyConfig.host,
          'port': widget.profile.proxyConfig.port,
        });
      }
    } catch (e) {
      print('[Browser] Android proxy error: $e');
    }
  }

  void _initMobileWebView() {
    _setAndroidProxy();

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
      
    // Android-specific optimizations
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      
      // Clear cache to ensure session isolation
      // Note: For full isolation on Android, consider using WebView profile API (Android 13+)
      androidController.clearCache();
    }
    
    _mobileController = controller;
    _mobileController.loadRequest(Uri.parse(_initialUrl));
  }

  // ========================================================================
  // NAVIGATION METHODS
  // ========================================================================
  
  void _loadUrl() {
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    
    if (Platform.isWindows) {
      _windowsController.loadUrl(url);
    } else {
      _mobileController.loadRequest(Uri.parse(url));
    }
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
              if (Platform.isWindows) {
                _windowsController.reload();
              } else {
                _mobileController.reload();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          Platform.isWindows
              ? (_windowsController.value.isInitialized
                  ? windows_webview.Webview(_windowsController)
                  : Container(color: Colors.black))
              : WebViewWidget(controller: _mobileController),
          
          // Progress bar
          if (_isWebViewLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
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
