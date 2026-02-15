import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/proxy/socks5_handler.dart';

/// Enhanced Windows Local Proxy Bridge
/// Supports both HTTP CONNECT and SOCKS5 proxies
/// Runs a local TCP server that forwards traffic to the upstream proxy
class WindowsLocalProxy {
  final ProxyType proxyType;
  final String upstreamHost;
  final int upstreamPort;
  final String? username;
  final String? password;
  
  ServerSocket? _server;
  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;

  WindowsLocalProxy({
    required this.proxyType,
    required this.upstreamHost,
    required this.upstreamPort,
    this.username,
    this.password,
  });

  /// Start the local proxy server
  Future<int> start() async {
    if (!Platform.isWindows) {
      print('[Proxy] Not running on Windows, skipping local proxy');
      return 0;
    }

    try {
      // Bind to random available port on localhost
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      print('[Proxy] Local proxy server started on 127.0.0.1:${_server!.port}');
      print('[Proxy] Type: $proxyType, Upstream: $upstreamHost:$upstreamPort');
      
      _server!.listen(_handleConnection);
      return _server!.port;
      
    } catch (e) {
      print('[Proxy] Failed to start local proxy server: $e');
      return 0;
    }
  }

  /// Stop the local proxy server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('[Proxy] Local proxy server stopped');
    }
  }

  /// Handle incoming connection based on proxy type
  void _handleConnection(Socket clientSocket) {
    print('[Proxy] New client connection from ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
    
    if (proxyType == ProxyType.socks5) {
      // Forward to SOCKS5 handler
      SOCKS5Handler.handleConnection(
        clientSocket,
        upstreamHost,
        upstreamPort,
        username,
        password,
      );
    } else {
      // HTTP CONNECT proxy (original implementation)
      _handleHttpConnect(clientSocket);
    }
  }

  /// Handle HTTP CONNECT proxy
  void _handleHttpConnect(Socket clientSocket) {
    bool headerProcessed = false;
    Socket? upstreamSocket;
    final List<int> buffer = [];

    // Pre-calculate Auth Header if credentials provided
    String? authHeader;
    if (username != null && password != null) {
      final authBase64 = base64Encode(utf8.encode('$username:$password'));
      authHeader = 'Proxy-Authorization: Basic $authBase64\\r\\n';
    }

    clientSocket.listen(
      (data) async {
        if (!headerProcessed) {
          buffer.addAll(data);
          
          // Check for end of headers (\\r\\n\\r\\n)
          final doubleCRLF = [13, 10, 13, 10];
          int headerEnd = _indexOf(buffer, doubleCRLF);

          if (headerEnd != -1) {
            headerProcessed = true;
            
            // Parse headers
            final fullHeaderBlock = buffer.sublist(0, headerEnd + 4);
            final bodyPending = buffer.sublist(headerEnd + 4);
            
            String headersStr = utf8.decode(fullHeaderBlock, allowMalformed: true);
            
            // Inject auth header if needed
            if (authHeader != null) {
              final firstLineEnd = headersStr.indexOf('\\r\\n');
              if (firstLineEnd != -1) {
                headersStr = headersStr.replaceRange(
                  firstLineEnd + 2,
                  firstLineEnd + 2,
                  authHeader,
                );
              }
            }

            try {
              // Connect to upstream proxy
              upstreamSocket = await Socket.connect(
                upstreamHost,
                upstreamPort,
                timeout: const Duration(seconds: 10),
              );

              print('[Proxy] Connected to upstream proxy $upstreamHost:$upstreamPort');

              // Send modified headers
              upstreamSocket!.add(utf8.encode(headersStr));
              
              // Send any pending body data
              if (bodyPending.isNotEmpty) {
                upstreamSocket!.add(bodyPending);
              }

              // Bidirectional relay
              upstreamSocket!.listen(
                (remoteData) {
                  try {
                    clientSocket.add(remoteData);
                  } catch (e) {
                    _close(clientSocket, upstreamSocket);
                  }
                },
                onError: (e) {
                  print('[Proxy] Upstream error: $e');
                  _close(clientSocket, upstreamSocket);
                },
                onDone: () => _close(clientSocket, upstreamSocket),
              );

            } catch (e) {
              print('[Proxy] Upstream connection failed: $e');
              _close(clientSocket, null);
            }
          }
        } else {
          // Tunnel established, relay data
          if (upstreamSocket != null) {
            try {
              upstreamSocket!.add(data);
            } catch (e) {
              _close(clientSocket, upstreamSocket);
            }
          }
        }
      },
      onError: (e) {
        print('[Proxy] Client error: $e');
        _close(clientSocket, upstreamSocket);
      },
      onDone: () => _close(clientSocket, upstreamSocket),
    );
  }

  /// Close connections
  void _close(Socket s1, Socket? s2) {
    try {
      s1.destroy();
    } catch (_) {}
    
    try {
      s2?.destroy();
    } catch (_) {}
  }

  /// Find pattern in buffer
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
