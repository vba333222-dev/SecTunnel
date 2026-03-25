import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:SecTunnel/models/proxy_config.dart';
import 'package:SecTunnel/services/proxy/http_connect_handler.dart';
import 'package:SecTunnel/services/proxy/socks5_handler.dart';

/// Unified proxy dispatcher.
///
/// Routes an incoming [client] socket to the correct upstream tunnel handler
/// based on [config.type]:
///
/// | ProxyType  | Handler               | Protocol            |
/// |------------|-----------------------|---------------------|
/// | `socks5`   | [SOCKS5Handler]       | RFC 1928 SOCKS5     |
/// | `http`     | [HttpConnectHandler]  | HTTP/1.1 CONNECT    |
/// | `none`     | throws                | —                   |
///
/// DNS leak prevention is guaranteed by both handlers: hostnames are forwarded
/// verbatim to the proxy server; no local DNS resolution is performed.
class ProxyRouter {
  ProxyRouter._(); // static-only class

  /// Route [client] traffic through the proxy described by [config] to
  /// [targetHost]:[targetPort].
  ///
  /// Throws [UnsupportedError] if `config.type == ProxyType.none`.
  /// Throws [StateError] if the config is incomplete (null host/port).
  static Future<void> handle({
    required Socket client,
    required ProxyConfig config,
    required String targetHost,
    required int targetPort,
  }) async {
    _assertConfigured(config);

    switch (config.type) {
      case ProxyType.socks5:
        debugPrint(
          '[ProxyRouter] SOCKS5 → ${config.host}:${config.port} '
          '| target: $targetHost:$targetPort',
        );
        await SOCKS5Handler.handleConnection(
          client,
          config.host!,
          config.port!,
          config.username,
          config.password,
        );

      case ProxyType.http:
        debugPrint(
          '[ProxyRouter] HTTP CONNECT → ${config.host}:${config.port} '
          '| target: $targetHost:$targetPort',
        );
        await HttpConnectHandler.handleConnection(
          clientSocket: client,
          proxyHost: config.host!,
          proxyPort: config.port!,
          targetHost: targetHost,
          targetPort: targetPort,
          username: config.username,
          password: config.password,
        );

      case ProxyType.none:
        throw UnsupportedError(
          '[ProxyRouter] ProxyType.none does not use a tunnel handler. '
          'Check isConfigured before calling handle().',
        );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _assertConfigured(ProxyConfig config) {
    if (config.host == null || config.host!.isEmpty) {
      throw StateError('[ProxyRouter] ProxyConfig.host is null/empty');
    }
    if (config.port == null) {
      throw StateError('[ProxyRouter] ProxyConfig.port is null');
    }
  }
}
