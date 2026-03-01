import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// SOCKS5 Protocol Handler
/// Implements SOCKS5 proxy protocol for connecting to SOCKS5 proxies
class SOCKS5Handler {
  static const int socks5Version = 0x05;
  static const int authMethodNone = 0x00;
  static const int authMethodUserPass = 0x02;
  static const int cmdConnect = 0x01;
  static const int atypIPv4 = 0x01;
  static const int atypDomainName = 0x03;
  
  /// Handle SOCKS5 connection between client and upstream proxy
  static Future<void> handleConnection(
    Socket clientSocket,
    String upstreamHost,
    int upstreamPort,
    String? username,
    String? password,
  ) async {
    Socket? upstreamSocket;
    
    try {
      // Connect to SOCKS5 proxy server
      upstreamSocket = await Socket.connect(
        upstreamHost,
        upstreamPort,
        timeout: const Duration(seconds: 10),
      );
      
      // Perform SOCKS5 handshake
      final success = await _performHandshake(
        upstreamSocket,
        username,
        password,
      );
      
      if (!success) {
        throw Exception('SOCKS5 handshake failed');
      }
      
      // Bidirectional relay
      _relayData(clientSocket, upstreamSocket);
      
    } catch (e) {
      debugPrint('[SOCKS5] Error: $e'); // Replaced multiple prints

      _closeConnections(clientSocket, upstreamSocket);
    }
  }
  
  /// Perform SOCKS5 handshake
  static Future<bool> _performHandshake(
    Socket upstreamSocket,
    String? username,
    String? password,
  ) async {
    try {
      // Step 1: Greeting
      final authMethods = (username != null && password != null)
          ? [authMethodUserPass]
          : [authMethodNone];
      
      final greeting = Uint8List.fromList([
        socks5Version,
        authMethods.length,
        ...authMethods,
      ]);
      
      upstreamSocket.add(greeting);
      await upstreamSocket.flush();
      
      // Read server choice
      final serverChoice = await _readBytes(upstreamSocket, 2);
      if (serverChoice == null || serverChoice[0] != socks5Version) {
        debugPrint('[SOCKS5] Invalid version in greeting response');
        return false;
      }
      
      final chosenMethod = serverChoice[1];
      
      // Step 2: Authentication (if required)
      if (chosenMethod == authMethodUserPass) {
        if (username == null || password == null) {
          debugPrint('[SOCKS5] Authentication required but no credentials provided');
          return false;
        }
        
        final authSuccess = await _performUserPassAuth(
          upstreamSocket,
          username,
          password,
        );
        
        if (!authSuccess) {
          debugPrint('[SOCKS5] Authentication failed');
          return false;
        }
      } else if (chosenMethod == authMethodNone) {
        // No authentication needed
      } else {
        debugPrint('[SOCKS5] Unsupported authentication method: $chosenMethod');
        return false;
      }
      
      return true;
      
    } catch (e) {
      debugPrint('[SOCKS5] Handshake error: $e');
      return false;
    }
  }
  
  /// Perform username/password authentication
  static Future<bool> _performUserPassAuth(
    Socket socket,
    String username,
    String password,
  ) async {
    try {
      final userBytes = utf8.encode(username);
      final passBytes = utf8.encode(password);
      
      final authRequest = Uint8List.fromList([
        0x01, // Auth version
        userBytes.length,
        ...userBytes,
        passBytes.length,
        ...passBytes,
      ]);
      
      socket.add(authRequest);
      await socket.flush();
      
      // Read auth response
      final authResponse = await _readBytes(socket, 2);
      if (authResponse == null || authResponse[1] != 0x00) {
        return false;
      }
      
      return true;
      
    } catch (e) {
      debugPrint('[SOCKS5] Auth error: $e');
      return false;
    }
  }
  
  /// Request connection to target via proxy
  static Future<bool> requestConnection(
    Socket socket,
    String targetHost,
    int targetPort,
  ) async {
    try {
      final hostBytes = utf8.encode(targetHost);
      final portBytes = [(targetPort >> 8) & 0xFF, targetPort & 0xFF];
      
      final request = Uint8List.fromList([
        socks5Version,
        cmdConnect,
        0x00, // Reserved
        atypDomainName,
        hostBytes.length,
        ...hostBytes,
        ...portBytes,
      ]);
      
      socket.add(request);
      await socket.flush();
      
      // Read response (at least 10 bytes: ver, rep, rsv, atyp, bnd.addr(4), bnd.port(2))
      final response = await _readBytes(socket, 10);
      if (response == null || response[0] != socks5Version) {
        return false;
      }
      
      final reply = response[1];
      if (reply != 0x00) {
        debugPrint('[SOCKS5] Connection request failed with reply: $reply');
        return false;
      }
      
      return true;
      
    } catch (e) {
      debugPrint('[SOCKS5] Connection request error: $e');
      return false;
    }
  }
  
  /// Relay data bidirectionally
  static void _relayData(Socket client, Socket upstream) {
    // Client -> Upstream
    client.listen(
      (data) {
        try {
          upstream.add(data);
        } catch (e) {
          _closeConnections(client, upstream);
        }
      },
      onError: (e) => _closeConnections(client, upstream),
      onDone: () => _closeConnections(client, upstream),
    );
    
    // Upstream -> Client
    upstream.listen(
      (data) {
        try {
          client.add(data);
        } catch (e) {
          _closeConnections(client, upstream);
        }
      },
      onError: (e) => _closeConnections(client, upstream),
      onDone: () => _closeConnections(client, upstream),
    );
  }
  
  /// Read exact number of bytes from socket
  static Future<Uint8List?> _readBytes(Socket socket, int count) async {
    final buffer = <int>[];
    
    try {
      await for (final chunk in socket.timeout(const Duration(seconds: 5))) {
        buffer.addAll(chunk);
        if (buffer.length >= count) {
          return Uint8List.fromList(buffer.sublist(0, count));
        }
      }
    } catch (e) {
      debugPrint('[SOCKS5] Read timeout or error: $e');
    }
    
    return null;
  }
  
  /// Close both connections
  static void _closeConnections(Socket? client, Socket? upstream) {
    try {
      client?.destroy();
    } catch (e) {
      // Ignore
    }
    
    try {
      upstream?.destroy();
    } catch (e) {
      // Ignore
    }
  }
}
