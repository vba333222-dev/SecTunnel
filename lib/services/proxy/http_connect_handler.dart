import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// HTTP CONNECT Tunnel Handler
///
/// Implements the HTTP/1.1 CONNECT method for tunnelling arbitrary TCP traffic
/// (typically TLS) through an HTTP proxy.
///
/// Protocol overview:
///   1. TCP connect to proxy host:port.
///   2. Send `CONNECT <targetHost>:<targetPort> HTTP/1.1` with optional
///      `Proxy-Authorization: Basic <base64(user:pass)>`.
///   3. Read the response line — assert `200 Connection established`.
///   4. After 200, the socket is a raw byte pipe: relay bidirectionally.
///
/// DNS-leak prevention: the CONNECT line carries the **hostname** verbatim;
/// DNS resolution is always performed by the proxy server, never by the client.
class HttpConnectHandler {
  // ── Timeouts ──────────────────────────────────────────────────────────────

  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _readTimeout = Duration(seconds: 8);

  // ── Public entry-points ───────────────────────────────────────────────────

  /// Establishes an HTTP CONNECT tunnel between [clientSocket] and the upstream
  /// HTTP proxy, then relays data bidirectionally.
  ///
  /// [proxyHost] / [proxyPort] — location of the HTTP proxy (e.g. 3proxy).
  /// [targetHost] / [targetPort] — final destination (hostname, not IP).
  /// [username] / [password] — if provided, a `Proxy-Authorization: Basic`
  ///   header is added; credentials are Base64-encoded.
  static Future<void> handleConnection({
    required Socket clientSocket,
    required String proxyHost,
    required int proxyPort,
    required String targetHost,
    required int targetPort,
    String? username,
    String? password,
  }) async {
    Socket? proxySocket;

    try {
      // 1. TCP connect to proxy.
      proxySocket = await Socket.connect(
        proxyHost,
        proxyPort,
        timeout: _connectTimeout,
      );
      debugPrint('[HttpConnect] Connected to proxy $proxyHost:$proxyPort');

      // 2. Send CONNECT request.
      final sent = await _sendConnectRequest(
        proxySocket,
        targetHost: targetHost,
        targetPort: targetPort,
        username: username,
        password: password,
      );
      if (!sent) throw Exception('CONNECT request failed to send');

      // 3. Read & validate 200 response.
      final ok = await _readConnectResponse(proxySocket);
      if (!ok) throw Exception('Proxy returned non-200 to CONNECT request');

      debugPrint('[HttpConnect] Tunnel established → $targetHost:$targetPort');

      // 4. Relay raw bytes bidirectionally.
      _relayData(clientSocket, proxySocket);
    } catch (e) {
      debugPrint('[HttpConnect] handleConnection error: $e');
      _closeConnections(clientSocket, proxySocket);
    }
  }

  /// Performs only a CONNECT request (without a client socket) and returns
  /// `true` if the proxy returns 200. Used by health-check code.
  ///
  /// The [proxySocket] must already be TCP-connected to the proxy server.
  static Future<bool> requestConnection(
    Socket proxySocket, {
    required String targetHost,
    required int targetPort,
    String? username,
    String? password,
  }) async {
    try {
      final sent = await _sendConnectRequest(
        proxySocket,
        targetHost: targetHost,
        targetPort: targetPort,
        username: username,
        password: password,
      );
      if (!sent) return false;

      return await _readConnectResponse(proxySocket);
    } catch (e) {
      debugPrint('[HttpConnect] requestConnection error: $e');
      return false;
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<bool> _sendConnectRequest(
    Socket socket, {
    required String targetHost,
    required int targetPort,
    String? username,
    String? password,
  }) async {
    try {
      final lines = StringBuffer()
        ..write('CONNECT $targetHost:$targetPort HTTP/1.1\r\n')
        ..write('Host: $targetHost:$targetPort\r\n')
        ..write('Proxy-Connection: Keep-Alive\r\n');

      // Inject Proxy-Authorization if credentials are present.
      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        final credentials = base64Encode(utf8.encode('$username:$password'));
        lines.write('Proxy-Authorization: Basic $credentials\r\n');
        debugPrint('[HttpConnect] Sending Basic auth for user "$username"');
      }

      lines.write('\r\n'); // End of headers.

      socket.add(utf8.encode(lines.toString()));
      await socket.flush();
      return true;
    } catch (e) {
      debugPrint('[HttpConnect] _sendConnectRequest error: $e');
      return false;
    }
  }

  /// Reads lines from [socket] until a blank line, returns `true` if the first
  /// status line contains `200`.
  static Future<bool> _readConnectResponse(Socket socket) async {
    try {
      final buffer = <int>[];
      bool? statusOk;

      await for (final chunk
          in socket.timeout(_readTimeout, onTimeout: (sink) => sink.close())) {
        buffer.addAll(chunk);

        // Scan for complete lines (LF or CRLF).
        while (true) {
          final lfIdx = buffer.indexOf(0x0A); // '\n'
          if (lfIdx == -1) break;

          int crlfIdx = lfIdx;
          if (lfIdx > 0 && buffer[lfIdx - 1] == 0x0D) { // '\r'
            crlfIdx = lfIdx - 1;
          }

          final line = utf8.decode(buffer.sublist(0, crlfIdx));
          buffer.removeRange(0, lfIdx + 1);

          if (statusOk == null) {
            // First line: "HTTP/1.x 200 Connection established"
            statusOk = line.contains(' 200 ') || line.endsWith(' 200');
            debugPrint('[HttpConnect] Status line: "\$line" → ok=\$statusOk');
            if (!statusOk) return false;
          } else if (line.isEmpty) {
            // Blank line = end of headers.
            return statusOk;
          }
          // Other header lines — ignore.
        }
      }

      return statusOk ?? false;
    } catch (e) {
      debugPrint('[HttpConnect] _readConnectResponse error: \$e');
      return false;
    }
  }

  // ── Relay ─────────────────────────────────────────────────────────────────

  static void _relayData(Socket client, Socket proxy) {
    // Client → Proxy
    client.listen(
      (data) {
        try {
          proxy.add(data);
        } catch (_) {
          _closeConnections(client, proxy);
        }
      },
      onError: (_) => _closeConnections(client, proxy),
      onDone: () => _closeConnections(client, proxy),
    );

    // Proxy → Client
    proxy.listen(
      (data) {
        try {
          client.add(data);
        } catch (_) {
          _closeConnections(client, proxy);
        }
      },
      onError: (_) => _closeConnections(client, proxy),
      onDone: () => _closeConnections(client, proxy),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _indexOfCRLF(List<int> buf) {
    for (int i = 0; i < buf.length - 1; i++) {
      if (buf[i] == 0x0D && buf[i + 1] == 0x0A) return i;
    }
    return -1;
  }

  static bool _endsWithDoubleNewline(List<int> buf) {
    // Check for \r\n\r\n at any point in the buffer.
    const pattern = [0x0D, 0x0A, 0x0D, 0x0A];
    outer:
    for (int i = 0; i <= buf.length - 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (buf[i + j] != pattern[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  static void _closeConnections(Socket? client, Socket? proxy) {
    for (final s in [client, proxy]) {
      try {
        s?.destroy();
      } catch (_) {}
    }
  }
}

