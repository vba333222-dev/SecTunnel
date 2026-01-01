import 'dart:async';
import 'dart:io';
import 'dart:ffi' hide Size; // For Native Interop
import 'package:ffi/ffi.dart'; // For Utf16 string conversion
import 'dart:convert'; // For safe JSON encoding

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for MethodChannel
import 'package:shared_preferences/shared_preferences.dart';

// Android/iOS WebView
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// Windows WebView & Window Manager
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import 'package:window_manager/window_manager.dart';

// ============================================================================
// 1. GLOBAL STATE MANAGEMENT
// ============================================================================

/// Global State to hold user credentials and session data.
/// Accessed by both HttpOverrides and UI/WebView logic.
class GlobalSession {
  static String username = '';
  static String password = '';
  
  static bool get isLoggedIn => username.isNotEmpty && password.isNotEmpty;

  static void clear() {
    username = '';
    password = '';
  }
}

// ============================================================================
// 2. CRITICAL NETWORK LOGIC (HTTP OVERRIDES)
// ============================================================================

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Note: HttpOverrides mainly affects Dart's internal HttpClient.
    // It DOES NOT affect the native WebView on Android/Windows directly,
    // but it ensures any Dart-side requests (if added later) use the proxy.
    
    final client = super.createHttpClient(context);
    
    // IP Whitelisting Requirement: COMPLETE AUTH SUPPRESSION (Server-side)
    client.authenticate = (url, scheme, realm) async => false;

    // DYNAMIC PROXY AUTHENTICATION
    // Injects the credentials stored in GlobalSession
    client.authenticateProxy = (host, port, scheme, realm) async {
       if (GlobalSession.isLoggedIn && realm != null) {
         client.addProxyCredentials(
           host, 
           port, 
           realm, 
           HttpClientBasicCredentials(GlobalSession.username, GlobalSession.password)
         );
         return true;
       }
       return false;
    };

    // PROXY CONFIGURATION
    client.findProxy = (uri) {
      // Force native proxy for everything unconditionally
      const proxy = "PROXY 72.62.122.59:59312;";
      // print("DEBUG: Proxying ${uri.host} via $proxy"); // Reduced log noise
      return proxy;
    };
    
    // Always trust certificates to prevent SSL handshake connection drops
    client.badCertificateCallback = (cert, host, port) => true;

    return client;
  }
}

// ============================================================================
// 3. NATIVE WINDOWS PROXY & EXTENSION INJECTION (FFI)
// ============================================================================

// Define C function signature: BOOL SetEnvironmentVariableW(LPCWSTR lpName, LPCWSTR lpValue)
typedef SetEnvironmentVariableC = Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue);
typedef SetEnvironmentVariableDart = int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue);

/// Injects the Proxy Server and optionally loads a Chrome Extension (for Auth).
void _injectWindowsProxy({String? extensionPath}) {
  if (!Platform.isWindows) return;

  try {
    // 1. Open Kernel32.dll
    final kernel32 = DynamicLibrary.open('kernel32.dll');

    // 2. Lookup SetEnvironmentVariableW
    final setEnvironmentVariable = kernel32.lookupFunction<
        SetEnvironmentVariableC, 
        SetEnvironmentVariableDart>('SetEnvironmentVariableW');

    // 3. Prepare Arguments (UTF-16 Strings)
    final name = 'WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS'.toNativeUtf16();
    
    // Workaround: Inject proxy via environment variable since plugin v0.4.0 blocks it in initialize()
    // Added flags to prevent extension throttling as requested
    String args = '--proxy-server=72.62.122.59:59312 --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding';
    
    // Dynamic Extension Injection for Basic Auth
    // FIX: MUST QUOTE THE PATH to handle spaces (e.g. "C:\Users\John Doe\...")
    if (extensionPath != null && extensionPath.isNotEmpty) {
      args += ' --load-extension="$extensionPath"';
    }

    final value = args.toNativeUtf16();

    // 4. Call Native API
    final result = setEnvironmentVariable(name, value);

    // 5. Cleanup Memory
    calloc.free(name);
    calloc.free(value);

    // 6. Verify result
    if (result == 0) {
      print('CRITICAL ERROR: Failed to inject Windows Proxy Environment Variable!');
    } else {
      print('SUCCESS: Native Windows Arguments Injected: $args');
    }
  } catch (e) {
    print('FATAL FFI ERROR: Could not set Windows Environment Variable: $e');
  }
}

/// Creates a temporary Chrome Extension to handle Proxy Authentication.
/// Returns the path to the extension folder.
Future<String> _createProxyAuthExtension(String username, String password) async {
  try {
    // 1. Create a temporary directory for the extension
    final tempDir = Directory.systemTemp.createTempSync('pbrowser_auth_ext_');
    final extPath = tempDir.path;

    // 2. Create manifest.json (Manifest V2)
    // FIX: Downgraded to Manifest V2 for persistent background page support
    // This prevents the Service Worker from sleeping and missing auth requests.
    final manifestContent = '''
{
  "manifest_version": 2,
  "name": "Proxy Auth",
  "version": "1.0",
  "permissions": [
    "webRequest",
    "webRequestBlocking",
    "<all_urls>"
  ],
  "background": {
    "scripts": ["background.js"],
    "persistent": true
  }
}
''';
    final manifestFile = File('$extPath${Platform.pathSeparator}manifest.json');
    await manifestFile.writeAsString(manifestContent);

    // Safe JSON Encoding for credentials to handle special characters properly
    final safeUsername = jsonEncode(username);
    final safePassword = jsonEncode(password);

    // 3. Create background.js
    // Listens for auth requests and provides credentials
    // Uses safe encoded strings directly
    final bgContent = '''
chrome.webRequest.onAuthRequired.addListener(
  function(details) {
    return {
      authCredentials: {
        username: $safeUsername,
        password: $safePassword
      }
    };
  },
  {urls: ["<all_urls>"]},
  ["blocking"]
);
''';
    final bgFile = File('$extPath${Platform.pathSeparator}background.js');
    await bgFile.writeAsString(bgContent);

    print("Created Auto-Auth Extension at: $extPath");
    return extPath;

  } catch (e) {
    print("Failed to create Auth Extension: $e");
    return "";
  }
}

// ============================================================================
// 4. MAIN ENTRY POINT
// ============================================================================

void main() async {
  // Note: We DO NOT call _injectWindowsProxy() here anymore because we need
  // the dynamic extension path which requires credentials (available after login).
  // The injection will happen in BrowserScreen just before WebView init.

  // Apply Dart-side network overrides
  HttpOverrides.global = MyHttpOverrides();
  
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Specific Initialization
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(1280, 720), // Enforce minimum size as requested
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const PBrowserApp());
}

class PBrowserApp extends StatelessWidget {
  const PBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PBrowser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Default to dark for clean UI
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueGrey,
          surface: Colors.black87,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================================
// 5. UI 1: LOGIN SCREEN (ENTRY POINT)
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    final savedPass = prefs.getString('password');

    if (savedUser != null && savedUser.isNotEmpty && 
        savedPass != null && savedPass.isNotEmpty) {
      // Auto-login logic
      GlobalSession.username = savedUser;
      GlobalSession.password = savedPass;
      
      if (mounted) {
        // Navigate to Synchronization (Splash)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false; // Show form
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);

    // Update Global State
    GlobalSession.username = username;
    GlobalSession.password = password;

    if (mounted) {
      // Navigate to Synchronization (Splash)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Clean dark theme
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'P-Browser Secure Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Connect Securely',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 6. SEQUENTIAL SYNCHRONIZATION (SPLASH SCREEN)
// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _statusMessage = 'Authenticating Secure Tunnel...';

  @override
  void initState() {
    super.initState();
    _startTransition();
  }

  Future<void> _startTransition() async {
    // Simple cosmetic delay to smooth out the transition
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BrowserScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. UI 2: BROWSER SCREEN (MAIN APP)
// ============================================================================

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  // Mobile Controller
  late final WebViewController _mobileController;
  // Windows Controller
  final windows_webview.WebviewController _windowsController = windows_webview.WebviewController();
  
  final TextEditingController _urlController = TextEditingController();
  static const platform = MethodChannel('com.example.pbrowser/proxy');
  
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  
  // Modern Android User-Agent
  static const String _userAgent = 
      "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) "
      "AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/120.0.6099.43 Mobile Safari/537.36";

  static const String _initialUrl = 'https://whoer.net/ip';

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
    }
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // WINDOWS INITIALIZATION
  // --------------------------------------------------------------------------
  Future<void> _initWindowsWebView() async {
    try {
      // 1. Generate the Auth Extension using GlobalCredentials
      // This creates a temp folder with manifest.json and background.js
      // which auto-responds to credential challenges.
      String extPath = await _createProxyAuthExtension(
        GlobalSession.username, 
        GlobalSession.password
      );

      // 2. Inject Proxy and Extension Config via FFI (Environment Variable)
      // This sets WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS for this process.
      _injectWindowsProxy(extensionPath: extPath);
      
      // 3. Initialize WebView (It will read the Env Var)
      await _windowsController.initialize();
      
      // Setup listeners
      _windowsController.url.listen((url) {
        if (mounted) {
           _urlController.text = url;
        }
      });

      _windowsController.loadingState.listen((state) {
        if (mounted) {
          if (state == windows_webview.LoadingState.loading) {
            setState(() {
               _isLoading = true;
               _loadingProgress = 0.5; // Indeterminate basically
            });
          } else if (state == windows_webview.LoadingState.navigationCompleted) {
            setState(() {
               _isLoading = false;
               _loadingProgress = 1.0;
            });
          }
        }
      });

      _windowsController.webMessage.listen((event) {
        // Handle web messages if needed
      });
      
      // Load Initial URL
      if (mounted) {
         _urlController.text = _initialUrl;
         await _windowsController.loadUrl(_initialUrl);
      }
      
    } on PlatformException catch (e) {
      print("Windows WebView Init Error: $e");
    }
  }

  // --------------------------------------------------------------------------
  // MOBILE (ANDROID/IOS) INITIALIZATION
  // --------------------------------------------------------------------------
  Future<void> _setNativeProxy() async {
    try {
      if (Platform.isAndroid) {
         // Note: Native proxy might not support Auth header injection easily on all Android versions
         // without user intervention or managed config. 
         // However, WebView's onHttpAuthRequest handles the Auth challenge from the proxy.
        //  print("DEBUG: Setting Native Android Proxy via Platform Channel");
        await platform.invokeMethod('setProxy', {
          'host': '72.62.122.59',
          'port': 59312,
        });
      }
    } on PlatformException catch (e) {
      print("DEBUG: Failed to set native proxy: '${e.message}'.");
    }
  }

  void _initMobileWebView() {
    _setNativeProxy();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_userAgent)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // WebRTC Leak Protection Logic
            controller.runJavaScript("""
              (function() {
                if (typeof window.RTCPeerConnection !== "undefined") { window.RTCPeerConnection = undefined; }
                if (typeof window.webkitRTCPeerConnection !== "undefined") { window.webkitRTCPeerConnection = undefined; }
                if (typeof window.mozRTCPeerConnection !== "undefined") { window.mozRTCPeerConnection = undefined; }
                if (typeof navigator.getUserMedia !== "undefined") { navigator.getUserMedia = undefined; }
                if (typeof navigator.webkitGetUserMedia !== "undefined") { navigator.webkitGetUserMedia = undefined; }
                if (typeof navigator.mozGetUserMedia !== "undefined") { navigator.mozGetUserMedia = undefined; }
                if (typeof navigator.mediaDevices !== "undefined") { navigator.mediaDevices = undefined; }
              })();
            """);

            if (mounted) {
              setState(() {
                _isLoading = true;
                _loadingProgress = 0.1;
                _urlController.text = url;
              });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress / 100);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
                _urlController.text = url;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print("DEBUG: WebView Error: ${error.description}");
            if (error.description.contains("net::ERR_PROXY_CONNECTION_FAILED") || 
                error.description.contains("net::ERR_TUNNEL_CONNECTION_FAILED") ||
                error.description.contains("407")) { // 407 = Proxy Auth Required
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text("Proxy Connection Error. Check credentials."),
                   backgroundColor: Colors.red,
                 ),
               );
            }
          },
          // CRITICAL: DYNAMIC PROXY AUTH INJECTION FOR WEBVIEW
          onHttpAuthRequest: (HttpAuthRequest request) {
             print("DEBUG: WebView Auth Request from ${request.host}");
             // If the request comes from our proxy or requires auth, inject GlobalSession creds
             // Note: request.host might differ from proxy host, but if it's the proxy challenging,
             // WebView usually handles it locally or via this callback. 
             // We blindly offer the global credentials if prompted.
             if (GlobalSession.isLoggedIn) {
                request.onProceed(
                  WebViewCredential(
                    user: GlobalSession.username, 
                    password: GlobalSession.password
                  ),
                );
             } else {
                request.onCancel();
              }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _mobileController = controller;
    _urlController.text = _initialUrl;
    _mobileController.loadRequest(Uri.parse(_initialUrl));
  }

  void _loadUrlFromTextField() {
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _urlController.text = url;
    }
    
    if (Platform.isWindows) {
      _windowsController.loadUrl(url);
    } else {
      _mobileController.loadRequest(Uri.parse(url));
    }
    
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _logout() async {
    // Clear Persisted Credentials
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Or remove specific keys
    
    // Clear Global State
    GlobalSession.clear();
    
    if (mounted) {
      // Navigate back to Login Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // --------------------------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Decide which WebView Widget to show
    Widget webViewWidget;
    if (Platform.isWindows) {
      // Windows WebView
      if (!_windowsController.value.isInitialized) {
        webViewWidget = const Center(child: Text("Initializing Windows Secure Engine..."));
      } else {
        webViewWidget = windows_webview.Webview(
          _windowsController,
        );
      }
    } else {
      // Mobile WebView
      // Note: We need to make sure _mobileController is initialized.
      // Since it's late, we assume it's done in initState.
      // But for safety, we could wrap in a builder.
      // For now we assume sync init in initState for mobile starts immediately.
      webViewWidget = WebViewWidget(controller: _mobileController);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: 'Back',
          onPressed: () async {
            if (Platform.isWindows) {
               _windowsController.goBack();
            } else {
              if (await _mobileController.canGoBack()) {
                _mobileController.goBack();
              }
            }
          },
        ),
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _urlController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              hintText: 'Search or enter URL',
              prefixIcon: const Icon(Icons.lock, size: 16, color: Colors.green),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _loadUrlFromTextField(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              if (Platform.isWindows) {
                _windowsController.reload();
              } else {
                _mobileController.reload();
              }
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2.0),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  color: Colors.blueAccent,
                  minHeight: 2.0,
                  ),
              )
            : null,
      ),
      body: webViewWidget,
    );
  }
}
