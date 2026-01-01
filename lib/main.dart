import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi' hide Size; 
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'dart:ui'; 

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Android/iOS WebView
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// Windows WebView & Window Manager
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import 'package:window_manager/window_manager.dart';

// ============================================================================
// 1. GLOBAL STATE
// ============================================================================

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
// 2. WINDOWS LOCAL PROXY BRIDGE
// ============================================================================

/// Runs a local TCP server that forwards traffic to the Real VPS
/// and injects the Proxy-Authorization header automatically.
class WindowsLocalProxy {
  final String upstreamHost;
  final int upstreamPort;
  final String username;
  final String password;
  
  ServerSocket? _server;
  int get port => _server?.port ?? 0;

  WindowsLocalProxy({
    required this.upstreamHost,
    required this.upstreamPort,
    required this.username,
    required this.password,
  });

  Future<int> start() async {
    // only runs on Windows (caller should check, but safety here is good)
    if (!Platform.isWindows) return 0;

    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      print('WindowsLocalProxy running on 127.0.0.1:${_server!.port}');
      _server!.listen(_handleConnection);
      return _server!.port;
    } catch (e) {
      print("Failed to start WindowsLocalProxy: $e");
      return 0;
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  void _handleConnection(Socket clientSocket) {
    bool headerProcessed = false;
    Socket? upstreamSocket;
    final List<int> buffer = [];

    // Pre-calculate Auth Header
    final authBase64 = base64Encode(utf8.encode('$username:$password'));
    final authHeader = 'Proxy-Authorization: Basic $authBase64\r\n';

    clientSocket.listen(
      (data) async {
        if (!headerProcessed) {
          buffer.addAll(data);
          // Check for end of headers
          final doubleCRLF = [13, 10, 13, 10]; // \r\n\r\n
          int headerEnd = _indexOf(buffer, doubleCRLF);

          if (headerEnd != -1) {
            headerProcessed = true;
            
            // 1. Parse current headers
            // We only need to inject the auth header into the handshake
            final fullHeaderBlock = buffer.sublist(0, headerEnd + 4);
            final bodyPending = buffer.sublist(headerEnd + 4);
            
            String headersStr = utf8.decode(fullHeaderBlock, allowMalformed: true);
            
            // 2. Inject Auth Header
            // Insert it after the Request Line (first line)
            final fileLineEnd = headersStr.indexOf('\r\n');
            if (fileLineEnd != -1) {
               headersStr = headersStr.replaceRange(fileLineEnd + 2, fileLineEnd + 2, authHeader);
            } else {
               // Fallback: just append if weird format
               headersStr += authHeader;
            }

            try {
              // 3. Connect to Real VPS
              upstreamSocket = await Socket.connect(upstreamHost, upstreamPort, timeout: const Duration(seconds: 10));

              // 4. Send modified headers + pending body
              upstreamSocket!.add(utf8.encode(headersStr));
              if (bodyPending.isNotEmpty) {
                upstreamSocket!.add(bodyPending);
              }

              // 5. Pipe Upstream -> Client
              upstreamSocket!.listen(
                (remoteData) {
                  try { clientSocket.add(remoteData); } catch (e) { _close(clientSocket, upstreamSocket); }
                },
                onError: (e) => _close(clientSocket, upstreamSocket),
                onDone: () => _close(clientSocket, upstreamSocket),
              );

            } catch (e) {
              print("Proxy Connection Failed: $e");
              _close(clientSocket, null);
            }
          }
          // If headers not full yet, keep buffering (rare for handshake)
        } else {
          // 6. Pipe Client -> Upstream (Tunnel established)
          if (upstreamSocket != null) {
            try { upstreamSocket!.add(data); } catch (e) { _close(clientSocket, upstreamSocket); }
          }
        }
      },
      onError: (e) => _close(clientSocket, upstreamSocket),
      onDone: () => _close(clientSocket, upstreamSocket),
    );
  }

  void _close(Socket s1, Socket? s2) {
     try { s1.destroy(); } catch (_) {}
     try { s2?.destroy(); } catch (_) {}
  }

  int _indexOf(List<int> source, List<int> pattern) {
    for (int i = 0; i < source.length - pattern.length + 1; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (source[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }
}

// ============================================================================
// 3. NATIVE FFI (WINDOWS ARGS)
// ============================================================================

typedef SetEnvC = Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue);
typedef SetEnvDart = int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue);

void _setWindowsProxyArg(int port) {
  if (!Platform.isWindows || port == 0) return;
  try {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final setEnv = kernel32.lookupFunction<SetEnvC, SetEnvDart>('SetEnvironmentVariableW');
    
    final name = 'WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS'.toNativeUtf16();
    // Use localhost proxy
    final args = '--proxy-server=127.0.0.1:$port --disable-background-timer-throttling'; 
    final value = args.toNativeUtf16();
    
    setEnv(name, value);
    
    calloc.free(name);
    calloc.free(value);
    print('Injecting WebView2 Args: $args');
  } catch (e) {
    print('FFI Error: $e');
  }
}

// ============================================================================
// 4. HTTP OVERRIDES (ANDROID-SAFE)
// ============================================================================

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // Trust all certs (Self-signed or Proxy MITM)
    client.badCertificateCallback = (cert, host, port) => true;
    
    // For Dart's HttpClient (not WebView), we can still use the GlobalSession logic
    // But the main traffic is in WebView.
    return client;
  }
}

// ============================================================================
// 5. MAIN ENTRY
// ============================================================================

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(1280, 720),
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueGrey,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================================
// 6. MODERN LOGIN SCREEN
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
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('username');
    final p = prefs.getString('password');
    if (u != null && u.isNotEmpty && p != null && p.isNotEmpty) {
      GlobalSession.username = u;
      GlobalSession.password = p;
      _navToBrowser();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final u = _usernameController.text.trim();
    final p = _passwordController.text.trim();
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter credentials")));
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', u);
    await prefs.setString('password', p);
    
    GlobalSession.username = u;
    GlobalSession.password = p;
    _navToBrowser();
  }

  void _navToBrowser() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BrowserScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1a233a), Colors.black],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO
                      Image.asset('assets/images/logo.png', height: 100),
                      const SizedBox(height: 24),
                      const Text(
                        "Secure Access",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 32),
                      _inputField(_usernameController, "Username", Icons.person_outline),
                      const SizedBox(height: 16),
                      _inputField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("CONNECT", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// ============================================================================
// 7. BROWSER SCREEN (WITH LOCAL BRIDGE INTEGRATION)
// ============================================================================

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _mobileController;
  final windows_webview.WebviewController _windowsController = windows_webview.WebviewController();
  final TextEditingController _urlController = TextEditingController();
  
  WindowsLocalProxy? _windowsProxy;
  static const String _initialUrl = 'https://whoer.net/ip';
  static const platform = MethodChannel('com.example.pbrowser/proxy');
  
  bool _isLoading = true; // Overall Loading Overlay State
  bool _isWebViewLoading = false; // Progress bar state
  double _progress = 0.0;

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

  // --------------------------------------------------------------------------
  // WINDOWS INIT (NEW ARCHITECTURE)
  // --------------------------------------------------------------------------
  Future<void> _initWindowsWebView() async {
    try {
      // 1. Start Local Proxy Server
      _windowsProxy = WindowsLocalProxy(
        upstreamHost: '72.62.122.59',
        upstreamPort: 59312,
        username: GlobalSession.username,
        password: GlobalSession.password,
      );
      
      int localPort = await _windowsProxy!.start();
      
      // 2. Inject environment variable to point to 127.0.0.1:localPort
      if (localPort > 0) {
        _setWindowsProxyArg(localPort);
      }

      // 3. Initialize WebView
      await _windowsController.initialize();
      
      // Listeners
      _windowsController.url.listen((url) { if (mounted) _urlController.text = url; });
      _windowsController.loadingState.listen((state) {
        if (mounted) {
           if (state == windows_webview.LoadingState.loading) {
             setState(() => _isWebViewLoading = true);
           } else if (state == windows_webview.LoadingState.navigationCompleted) {
             setState(() => _isWebViewLoading = false);
           }
        }
      });

      // 4. Wait Buffer (Socket readiness)
      await Future.delayed(const Duration(seconds: 2));

      // 5. Load Initial URL
      if (mounted) {
        setState(() => _isLoading = false); // Hide Overlay
        _urlController.text = _initialUrl;
        await _windowsController.loadUrl(_initialUrl);
      }

    } catch (e) {
      print("Windows Init Error: $e");
    }
  }

  // --------------------------------------------------------------------------
  // ANDROID INIT (LEGACY - UNTOUCHED LOGIC)
  // --------------------------------------------------------------------------
  Future<void> _setAndroidProxy() async {
    try {
      if (Platform.isAndroid) {
         await platform.invokeMethod('setProxy', {'host': '72.62.122.59', 'port': 59312});
      }
    } catch (e) { print("Android Proxy Error: $e"); }
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
          onPageStarted: (url) { 
            if (mounted) setState(() { _isWebViewLoading = true; _urlController.text = url; });
          },
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageFinished: (url) { 
            if (mounted) setState(() { _isLoading = false; _isWebViewLoading = false; _urlController.text = url; });
          },
          onHttpAuthRequest: (request) {
            // Android uses Native Auth Handler
             if (GlobalSession.isLoggedIn) {
                request.onProceed(WebViewCredential(user: GlobalSession.username, password: GlobalSession.password));
             } else {
                request.onCancel();
              }
          },
        ),
      );
      
    if (controller.platform is AndroidWebViewController) {
       (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    
    _mobileController = controller;
    _mobileController.loadRequest(Uri.parse(_initialUrl));
  }

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
  
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    GlobalSession.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // --------------------------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: "Enter URL",
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.shield_outlined, size: 16, color: Colors.green),
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: (_) => _loadUrl(),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => Platform.isWindows ? _windowsController.reload() : _mobileController.reload()),
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout),
        ],
      ),
      body: Stack(
        children: [
          // 1. WebView
          Platform.isWindows 
             ? (_windowsController.value.isInitialized ? windows_webview.Webview(_windowsController) : Container(color: Colors.black))
             : WebViewWidget(controller: _mobileController),
          
          // 2. Progress Bar
          if (_isWebViewLoading)
             const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2, color: Colors.blueAccent)),
             
          // 3. Loading Overlay (Initial Load)
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', width: 60),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
