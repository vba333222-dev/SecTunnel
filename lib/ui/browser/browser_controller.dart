import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'package:sec_tunnel/models/browser_profile.dart';
import 'package:sec_tunnel/models/user_script.dart' as models;
import 'package:sec_tunnel/models/fingerprint_config.dart';
import 'package:sec_tunnel/models/proxy_config.dart';
import 'package:sec_tunnel/services/fingerprint/fingerprint_injector.dart';
import 'package:sec_tunnel/services/browser/cookie_manager_service.dart';
import 'package:sec_tunnel/services/browser/userscript_service.dart';
import 'package:sec_tunnel/services/proxy/proxy_health_check.dart';
import 'package:sec_tunnel/services/proxy/geo_ip_service.dart';
import 'package:sec_tunnel/repositories/profile_repository.dart';
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';

import 'browser_state.dart';

class BrowserController extends ChangeNotifier {
  BrowserState state = const BrowserState();
  
  final BrowserProfile profile;
  final BuildContext context; // To access providers

  InAppWebViewController? webViewController;
  final TextEditingController urlController = TextEditingController();

  late FingerprintConfig activeFingerprint;
  late InAppWebViewSettings webViewSettings;
  WebViewEnvironment? environment;
  List<models.UserScript> activeScripts = [];
  List<UserScript> generatedUserScripts = [];

  static final Map<int, InAppWebViewController> _activeProxyConnections = {};
  static const platform = MethodChannel('com.example.pbrowser/proxy');

  bool get hasProxy => profile.proxyConfig.type != ProxyType.none;

  bool _isDisposed = false;

  BrowserController({required this.profile, required this.context}) {
    activeFingerprint = profile.fingerprintConfig;
    urlController.text = state.currentUrl;
  }

  void _updateState(BrowserState newState) {
    if (_isDisposed) return;
    state = newState;
    notifyListeners();
  }

  Future<void> initializeApp() async {
    final proxyPort = profile.proxyConfig.port;
    if (proxyPort != null && _activeProxyConnections.containsKey(proxyPort)) {
      debugPrint('[Browser] Neutralizing ghost WebView instance occupying Port $proxyPort');
      try {
        final ghost = _activeProxyConnections[proxyPort];
        ghost?.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
        ghost?.dispose();
      } catch (_) {}
      _activeProxyConnections.remove(proxyPort);
    }

    final userScriptService = Provider.of<UserScriptService>(context, listen: false);
    activeScripts = await userScriptService.getActiveScripts(profile.id);

    // 1. Health Check
    final preFlight = await ProxyHealthCheckService.runPreFlightCheck(profile.proxyConfig);
    if (!preFlight.isHealthy) {
      _updateState(state.copyWith(
        isLoading: false,
        isProxyHealthy: false,
        errorReason: preFlight.errorReason,
      ));
      return;
    }

    // 2. Fetch Sandbox Context (GeoIP, Timezone) based on Proxy IP
    try {
      final geoData = await GeoIpService.fetchGeoData(profile.proxyConfig);
      if (geoData != null) {
        final countryCode = geoData['countryCode'] as String;
        final lang = GeoIpService.countryCodeToLanguage(countryCode);

        activeFingerprint = activeFingerprint.copyWith(
          timezone: geoData['timezone'] as String,
          language: lang,
          geolocation: GeolocationConfig(
            latitude: geoData['latitude'] as double,
            longitude: geoData['longitude'] as double,
            accuracy: 45.0 + (DateTime.now().millisecond % 15.0),
          ),
        );
        _updateState(state.copyWith(currentPublicIp: null));
      }
    } catch (e) {
      debugPrint('[Browser] Failed to dynamically sync Geo-IP: $e');
    }

    // 3. Set the profile data directory suffix FIRST
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod<bool>('setProfileDirectory', {'profileId': profile.id});
      } catch (e) {
        debugPrint('[Browser] setProfileDirectory error: $e');
      }
    }

    // 4. Set Proxy configuration
    await _setAndroidProxy();

    // 5. Setup native InAppWebViewEnvironment and Settings
    try {
      environment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: profile.userDataFolder,
        ),
      );
    } catch (e) {
      debugPrint('[Browser] Failed to create WebViewEnvironment: $e');
    }

    webViewSettings = InAppWebViewSettings(
      userAgent: activeFingerprint.userAgent,
      javaScriptEnabled: true,
      transparentBackground: false,
      clearCache: profile.clearBrowsingData,
      useShouldInterceptRequest: true,
      useShouldInterceptFetchRequest: true,
      useShouldInterceptAjaxRequest: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      javaScriptCanOpenWindowsAutomatically: false,
      incognito: false,
    );

    // Prepare UserScripts for Anti-Detect mechanism
    final injector = FingerprintInjector(activeFingerprint);
    generatedUserScripts = injector.generateUserScripts();

    // Load cookies from SQLite DB securely
    try {
      final cookies = await CookieManagerService.loadSessionFromDb(profile.userDataFolder);
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

    // Ready
    _updateState(state.copyWith(
      isControllerInitialized: true,
      isLoading: false,
    ));

    if (profile.clearBrowsingData) {
      try {
        // ignore: use_build_context_synchronously
        final repo = Provider.of<ProfileRepository>(context, listen: false);
        await repo.updateProfile(profile.copyWith(clearBrowsingData: false));
      } catch (e) {
        debugPrint('[Browser] Failed to reset clearBrowsingData flag: $e');
      }
    }

    _fetchPublicIp();
  }

  Future<void> _setAndroidProxy() async {
    final proxyConfig = profile.proxyConfig;
    final proxyHost = proxyConfig.host;
    final proxyPort = proxyConfig.port;
    final proxyType = proxyConfig.type;
    final proxyUser = proxyConfig.username;
    final proxyPass = proxyConfig.password;

    if (!proxyConfig.isConfigured || proxyHost == null || proxyPort == null) {
      return;
    }

    if (proxyHost.contains('sectunnel.online')) {
      try {
        final scheme = proxyType == ProxyType.socks5 ? 'socks5' : 'http';
        String proxyUrl;
        if (proxyUser != null && proxyPass != null && proxyUser.isNotEmpty && proxyPass.isNotEmpty) {
          proxyUrl = '$scheme://$proxyUser:$proxyPass@$proxyHost:$proxyPort';
        } else {
          proxyUrl = '$scheme://$proxyHost:$proxyPort';
        }
        await ProxyController.instance().setProxyOverride(
          settings: ProxySettings(proxyRules: [ProxyRule(url: proxyUrl)]),
        );
      } catch (e) {
        debugPrint('[Browser] ProxyController.setProxyOverride error: $e');
      }
    } else {
      final scheme = proxyType == ProxyType.socks5 ? 'socks5' : 'http';
      String proxyUrl;
      if (proxyUser != null && proxyPass != null && proxyUser.isNotEmpty && proxyPass.isNotEmpty) {
        proxyUrl = '$scheme://$proxyUser:$proxyPass@$proxyHost:$proxyPort';
      } else {
        proxyUrl = '$scheme://$proxyHost:$proxyPort';
      }

      try {
        await ProxyController.instance().setProxyOverride(
          settings: ProxySettings(proxyRules: [ProxyRule(url: proxyUrl)]),
        );
      } catch (e) {
        debugPrint('[Browser] ProxyController.setProxyOverride error: $e');
      }
    }

    try {
      if (Platform.isAndroid && proxyConfig.isConfigured) {
        await platform.invokeMethod('setProxy', {
          'host': proxyHost,
          'port': proxyPort,
          'scheme': proxyType.toString(),
          'username': proxyUser,
          'password': proxyPass,
        });
      }
    } catch (e) {
      debugPrint('[Browser] Native setProxy MethodChannel error: $e');
    }
  }

  Future<void> _fetchPublicIp() async {
    if (_isDisposed || !hasProxy) return;
    if (state.isIpFetching) return;

    _updateState(state.copyWith(isIpFetching: true));
    try {
      final ip = await GeoIpService.fetchIpAddress(profile.proxyConfig);
      if (_isDisposed) return;
      
      if (ip != null && ip.isNotEmpty) {
        _updateState(state.copyWith(currentPublicIp: ip));
      } else {
        final geoData = await GeoIpService.fetchGeoData(profile.proxyConfig);
        if (_isDisposed) return;
        if (geoData != null && geoData['ip'] != null) {
          _updateState(state.copyWith(currentPublicIp: geoData['ip'] as String));
        } else {
          _updateState(state.copyWith(currentPublicIp: null));
        }
      }
    } catch (_) {
      if (!_isDisposed) _updateState(state.copyWith(currentPublicIp: null));
    } finally {
      if (!_isDisposed) _updateState(state.copyWith(isIpFetching: false));
    }
  }

  Future<void> rotateIpNow() async {
    if (state.isRotating) return;

    _updateState(state.copyWith(isRotating: true));
    HapticFeedback.heavyImpact();

    try {
      if (webViewController != null) {
        try {
          await webViewController!.evaluateJavascript(source: 'window.stop();');
        } catch (_) {}
      }

      // ignore: use_build_context_synchronously
      await context.read<ModemRotatorService>().rotateIp(profile.id, profile.name);
      await Future.delayed(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[HUD] Rotation error: $e');
    } finally {
      HapticFeedback.vibrate();
      if (!_isDisposed) {
        _updateState(state.copyWith(isRotating: false));
        await _fetchPublicIp();
      }
    }
  }

  Future<void> rotateAndRetry() async {
    await rotateIpNow();
    if (_isDisposed) return;
    await Future.delayed(const Duration(seconds: 4));
    if (_isDisposed) return;
    _updateState(state.copyWith(isLoading: true, isProxyHealthy: true));
    initializeApp();
  }

  void retryConnection() {
    _updateState(state.copyWith(isLoading: true, isProxyHealthy: true));
    initializeApp();
  }

  void bypassProxyAndLoad() {
    _updateState(state.copyWith(isLoading: true, isProxyHealthy: true));
    initializeApp();
  }

  void loadUrl(String query) {
    if (!state.isProxyHealthy || state.isRotating) return;
    
    String url = query.trim();
    if (url.isEmpty) return;
    
    final hasDomain = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z]{2,}').hasMatch(url);
    final hasTLD = url.contains('.') && url.split('.').last.length >= 2;
    
    if (!url.startsWith('http') && (!hasDomain || !hasTLD)) {
      final encodedQuery = Uri.encodeComponent(url);
      url = 'https://duckduckgo.com/?q=$encodedQuery';
    } else if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    
    webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void goBack() async {
    if (await webViewController?.canGoBack() ?? false) {
      webViewController?.goBack();
    }
  }

  void goForward() async {
    if (await webViewController?.canGoForward() ?? false) {
      webViewController?.goForward();
    }
  }

  void reload() {
    if (state.isControllerInitialized && state.isProxyHealthy) {
      webViewController?.reload();
    } else if (!state.isProxyHealthy) {
      retryConnection();
    }
  }

  void injectNativeTouch(double x, double y) {
    if (Platform.isAndroid) {
      try {
        platform.invokeMethod('injectTouch', {'x': x, 'y': y});
      } catch (e) {
        debugPrint('[Browser] Failed to inject touch: $e');
      }
    }
  }

  void toggleHud() {
    _updateState(state.copyWith(hudExpanded: !state.hudExpanded));
  }
  
  Future<void> clearSession() async {
    InAppWebViewController.clearAllCache();
  }

  // WebView Callbacks
  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    final pPort = profile.proxyConfig.port;
    if (pPort != null) {
      _activeProxyConnections[pPort] = controller;
    }
  }

  void onLoadStart(InAppWebViewController controller, WebUri? url) {
    final urlStr = url?.toString() ?? '';
    urlController.text = urlStr;
    _updateState(state.copyWith(isWebViewLoading: true, currentUrl: urlStr));

    for (final script in activeScripts) {
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
  }

  void onLoadStop(InAppWebViewController controller, WebUri? url) {
    final urlStr = url?.toString() ?? '';
    urlController.text = urlStr;
    _updateState(state.copyWith(isWebViewLoading: false, currentUrl: urlStr));

    for (final script in activeScripts) {
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
  }

  void onProgressChanged(InAppWebViewController controller, int progress) {
    _updateState(state.copyWith(progress: progress / 100));
  }

  Future<WebResourceResponse?> shouldInterceptRequest(InAppWebViewController controller, WebResourceRequest request) async {
    if (state.isRotating) {
      return WebResourceResponse(
        statusCode: 403,
        reasonPhrase: 'Proxy Rotating',
        data: Uint8List(0),
      );
    }
    return null;
  }

  Future<FetchRequest?> shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest request) async {
    request.headers ??= {};
    request.headers!['User-Agent'] = activeFingerprint.userAgent;
    if (activeFingerprint.secChUa.isNotEmpty) {
      request.headers!['Sec-CH-UA'] = activeFingerprint.secChUa;
      request.headers!['Sec-CH-UA-Mobile'] =
          activeFingerprint.platform.toLowerCase().contains('android') ? '?1' : '?0';
      request.headers!['Sec-CH-UA-Platform'] = '"${activeFingerprint.platform}"';
    }
    return request;
  }

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction action) async {
    if (state.isRotating) {
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<HttpAuthResponse?> onReceivedHttpAuthRequest(InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
    final expectedHost = profile.proxyConfig.host;
    final proxyUsername = profile.proxyConfig.username ?? 'admin';
    final proxyPassword = profile.proxyConfig.password ?? 'rotator123';

    bool hostMatches = challenge.protectionSpace.host == expectedHost;

    if (hostMatches) {
      return HttpAuthResponse(
        username: proxyUsername,
        password: proxyPassword,
        action: HttpAuthResponseAction.PROCEED,
      );
    } else {
      return HttpAuthResponse(action: HttpAuthResponseAction.CANCEL);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    urlController.dispose();
    activeScripts.clear();
    
    final proxyPort = profile.proxyConfig.port;
    if (proxyPort != null) {
      _activeProxyConnections.remove(proxyPort);
    }

    try {
      platform.invokeMethod('flushCookies').whenComplete(() {
        if (Platform.isAndroid) {
          CookieManagerService.exportCookies(profile.id).then((cookies) {
            CookieManagerService.saveSessionToDb(profile.userDataFolder, cookies);
          }).catchError((e) {
            debugPrint('[Browser] Background session cookie export failed: $e');
          });
        }
      });
    } catch (_) {}

    if (webViewController != null) {
      try {
        webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
        InAppWebViewController.clearAllCache();
        webViewController!.dispose();
      } catch (e) {
        debugPrint('[Browser] Error during WebView dispose cleanup: $e');
      }
      webViewController = null;
    }
    
    super.dispose();
  }
}
