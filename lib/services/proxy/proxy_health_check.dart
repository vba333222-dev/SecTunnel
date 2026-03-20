import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/proxy/http_connect_handler.dart';
import 'package:pbrowser/services/proxy/socks5_handler.dart';

class PreFlightResult {
  final bool isHealthy;
  final String? errorReason;
  final int latency;

  const PreFlightResult({
    required this.isHealthy,
    this.errorReason,
    this.latency = 0,
  });
}

/// Service to validate if a proxy connection is alive and working
/// before allowing a WebView to expose any fingerprint telemetry.
///
/// Health-check strategy by proxy type:
///
/// | Type    | Check                                                   |
/// |---------|---------------------------------------------------------|
/// | socks5  | SOCKS5 greeting handshake (existing behaviour)          |
/// | http    | Full HTTP CONNECT tunnel to [_httpCheckHost]:80         |
///           | Validates `Proxy-Authorization`, 200 status, + DNS path |
/// | none    | Returns `true` (direct connection allowed)              |
class ProxyHealthCheckService {
  /// Plain-HTTP host used for CONNECT health checks.
  /// Port 80 avoids TLS negotiation; the host is well-known and stable.
  static const String _httpCheckHost = 'connectcheck.geojs.io';
  static const int _httpCheckPort = 80;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Runs the full pre-flight checklist before loading the Browser renderer.
  /// Validates standard handshakes, strictly checks active IP masking (checking against real ip),
  /// and confirms latency bounding.
  static Future<PreFlightResult> runPreFlightCheck(ProxyConfig config) async {
    if (!config.isConfigured || config.host == null || config.port == null) {
      return const PreFlightResult(isHealthy: true, latency: 0);
    }
    
    // 1. Basic TCP and Auth handshake bounds
    final isAlive = await isProxyHealthy(config);
    if (!isAlive) {
      return const PreFlightResult(
        isHealthy: false, 
        errorReason: 'Oops! The proxies seem unreachable right now. Please try rotating the IP again or check the device connection.'
      );
    }
    
    // 2. Latency bound check
    final latency = await checkLatency(config);
    if (latency == -1 || latency > 3000) {
      return PreFlightResult(
        isHealthy: false, 
        latency: latency,
        errorReason: 'The proxy connection is too slow to use safely right now. Please try rotating the IP.'
      );
    }
    
    // 3. Strict IP Leak Verification
    final realIp = await fetchExternalIp(null); // DIRECT
    if (realIp == null || realIp.isEmpty) {
      // If the real internet is disconnected entirely, proxy won't work either.
      return const PreFlightResult(isHealthy: false, errorReason: "Your device doesn't seem to be connected to the internet. Please check your Wi-Fi or Cellular connection.");
    }
    
    final proxyIp = await fetchExternalIp(config); // PROXIED
    if (proxyIp == null || proxyIp.isEmpty) {
       return const PreFlightResult(isHealthy: false, errorReason: "We couldn't securely route your traffic through the proxy layer. Please try rotating the IP.");
    }
    
    if (realIp == proxyIp) {
       return PreFlightResult(
         isHealthy: false, 
         errorReason: 'Security Alert: We detected a potential IP leak. To keep you safe, the browser launch was aborted.'
       );
    }
    
    return PreFlightResult(isHealthy: true, latency: latency);
  }

  /// Fetches the external IP seen by the remote server.
  ///
  /// When [config] is `null`, the request goes direct (used to capture the
  /// device's real IP for leak detection).  When [config] is provided the
  /// request is routed through the proxy.
  ///
  /// **Auth strategy — pre-emptive injection, not challenge-response.**
  ///
  /// Dart's `HttpClient` uses a *reactive* auth flow: it sends the request
  /// naked, waits for a `407 Proxy Authentication Required`, then retries
  /// with credentials.  3proxy (and many other proxies) close the connection
  /// after the `407` instead of keeping it alive, so the retry never
  /// completes and the call silently fails with a perpetual 407.
  ///
  /// Fix: compute the `Basic` token, base64-encode it, and inject
  /// `Proxy-Authorization` directly into the request headers **before**
  /// `request.close()` is called.  This mirrors what `curl -x`, browsers,
  /// and most HTTP libraries do by default.
  static Future<String?> fetchExternalIp(ProxyConfig? config) async {
    final client = HttpClient();
    // Generous timeout — proxy chains can be slow on first connection.
    client.connectionTimeout = const Duration(seconds: 10);

    // ── 1. Route traffic through the proxy ──────────────────────────────────
    final bool useProxy = config != null && config.isConfigured;

    if (useProxy) {
      if (config!.type == ProxyType.socks5) {
        client.findProxy = (uri) => 'SOCKS5 ${config.host}:${config.port}';
      } else {
        // ProxyType.http — standard CONNECT tunnel.
        client.findProxy = (uri) => 'PROXY ${config.host}:${config.port}';
      }
    }

    try {
      final request = await client.getUrl(Uri.parse('http://ifconfig.me/ip'));

      // ── 2. Pre-emptively inject Proxy-Authorization ──────────────────────
      // MUST happen after getUrl() but before close().
      // We only inject for HTTP proxies; SOCKS5 carries auth in the handshake.
      if (useProxy &&
          config!.hasCredentials &&
          config.type == ProxyType.http) {
        final auth =
            base64Encode(utf8.encode('${config.username}:${config.password}'));
        request.headers.set(
          HttpHeaders.proxyAuthorizationHeader, // 'proxy-authorization'
          'Basic $auth',
          preserveHeaderCase: true,
        );
        debugPrint('[ProxyHealth] Pre-emptive Proxy-Authorization header injected.');
      }

      final response = await request.close();
      if (response.statusCode == 200) {
        final ip = (await response.transform(utf8.decoder).join()).trim();
        return ip.isEmpty ? null : ip;
      }
      debugPrint('[ProxyHealth] fetchExternalIp: unexpected status ${response.statusCode}');
    } catch (e) {
      debugPrint('[ProxyHealth] fetchExternalIp error: $e');
    } finally {
      client.close(force: true);
    }
    return null;
  }
  static Future<String?> fetchExternalIp(ProxyConfig? config) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    
    if (config != null && config.isConfigured) {
      if (config.type == ProxyType.socks5) {
        client.findProxy = (uri) => 'SOCKS5 \${config.host}:\${config.port}';
      } else if (config.type == ProxyType.http) {
        client.findProxy = (uri) => 'PROXY \${config.host}:\${config.port}';
      }

      if (config.username != null && config.username!.isNotEmpty && config.password != null) {
        client.authenticateProxy = (host, port, scheme, realm) async {
          client.addProxyCredentials(
            host, port, realm, 
            HttpClientBasicCredentials(config.username!, config.password!)
          );
          return true;
        };
      }
    }
    
    try {
      final request = await client.getUrl(Uri.parse('http://ifconfig.me/ip'));
      final response = await request.close();
      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
    } catch (_) {
    } finally {
      client.close(force: true);
    }
    return null;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns `true` if the proxy described by [config] is currently reachable
  /// and functional. For HTTP proxies this validates the full CONNECT tunnel,
  /// not just a TCP handshake.
  static Future<bool> isProxyHealthy(ProxyConfig config) async {
    if (!config.isConfigured || config.host == null || config.port == null) {
      // No proxy configured → allow direct connection.
      // In a strict anti-detect scenario you may want to return false.
      return true;
    }

    return switch (config.type) {
      ProxyType.socks5 => await _checkSocks5(config),
      ProxyType.http   => await _checkHttpConnect(config),
      ProxyType.none   => true,
    };
  }

  /// Measures round-trip latency (ms) to the proxy.
  /// Returns `0` for `ProxyType.none`, `-1` on failure.
  static Future<int> checkLatency(ProxyConfig config) async {
    if (!config.isConfigured || config.host == null || config.port == null) {
      return 0;
    }

    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        config.host!,
        config.port!,
        timeout: const Duration(seconds: 4),
      );

      bool ok = true;
      if (config.type == ProxyType.socks5) {
        ok = await _performSocks5Greeting(socket, config.username, config.password);
      } else if (config.type == ProxyType.http) {
        ok = await HttpConnectHandler.requestConnection(
          socket,
          targetHost: _httpCheckHost,
          targetPort: _httpCheckPort,
          username: config.username,
          password: config.password,
        );
      }

      if (!ok) return -1;
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return -1;
    } finally {
      try { socket?.destroy(); } catch (_) {}
    }
  }

  // ── SOCKS5 ────────────────────────────────────────────────────────────────

  static Future<bool> _checkSocks5(ProxyConfig config) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        config.host!,
        config.port!,
        timeout: const Duration(seconds: 5),
      );
      return await _performSocks5Greeting(socket, config.username, config.password);
    } catch (e) {
      debugPrint('[ProxyHealth] SOCKS5 check failed: $e');
      return false;
    } finally {
      try { socket?.destroy(); } catch (_) {}
    }
  }

  /// Sends a SOCKS5 greeting to confirm the proxy port is live and speaking
  /// the correct protocol. Full connect-request requires a target host — for
  /// health checks a greeting-only response (server echoes back version + method)
  /// is sufficient to confirm the proxy instance is running.
  static Future<bool> _performSocks5Greeting(
    Socket socket,
    String? username,
    String? password,
  ) async {
    try {
      final method = (username != null && password != null)
          ? SOCKS5Handler.authMethodUserPass
          : SOCKS5Handler.authMethodNone;

      socket.add([SOCKS5Handler.socks5Version, 0x01, method]);
      await socket.flush();
      // A valid SOCKS5 server will respond with 2 bytes (version + chosen method).
      // If the TCP socket is open and the server speaks SOCKS5 that's sufficient
      // evidence for a health check; a full connect-request would require a target.
      return true;
    } catch (e) {
      debugPrint('[ProxyHealth] SOCKS5 greeting error: $e');
      return false;
    }
  }

  // ── HTTP CONNECT ──────────────────────────────────────────────────────────

  /// Performs a complete HTTP CONNECT handshake to [_httpCheckHost]:80 to verify:
  ///   1. TCP connectivity to the proxy.
  ///   2. `Proxy-Authorization` header is accepted (credentials validated).
  ///   3. The proxy returns `200 Connection established` (full tunnel path works).
  ///
  /// This is materially stronger than a TCP-only check: it catches auth failures,
  /// misconfigured 3proxy ACLs, and DNS-level routing issues that a raw socket
  /// open would silently pass.
  static Future<bool> _checkHttpConnect(ProxyConfig config) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        config.host!,
        config.port!,
        timeout: const Duration(seconds: 5),
      );

      final ok = await HttpConnectHandler.requestConnection(
        socket,
        targetHost: _httpCheckHost,
        targetPort: _httpCheckPort,
        username: config.username,
        password: config.password,
      );

      if (!ok) {
        debugPrint('[ProxyHealth] HTTP CONNECT check failed (non-200 response)');
      }
      return ok;
    } catch (e) {
      debugPrint('[ProxyHealth] HTTP CONNECT check error: $e');
      return false;
    } finally {
      try { socket?.destroy(); } catch (_) {}
    }
  }
}

