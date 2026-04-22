import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:SecTunnel/models/proxy_config.dart';

class ProxyRotationException implements Exception {
  final String message;
  ProxyRotationException(this.message);
  @override
  String toString() => message;
}

/// Service to handle rotating IPs.
/// Supports both direct API and proxy-tunneled connections.
class MobileProxyService {
  static Future<void> rotateIp({
    required String rotationUrl,
    String? proxyHost,
    String? proxyUser,
    String? proxyPass,
  }) async {
    if (rotationUrl.trim().isEmpty) {
      throw ProxyRotationException('Rotation URL is missing. Please check your settings.');
    }

    debugPrint('[MobileProxyService] Rotating IP via: $rotationUrl');

    try {
      // If using proxy tunnel
      if (proxyHost != null && proxyHost.contains('sectunnel.online')) {
        await _rotateViaProxy(
          rotationUrl: rotationUrl,
          proxyHost: proxyHost,
          username: proxyUser ?? 'admin',
          password: proxyPass ?? 'rotator123',
        );
      } else {
        // Direct rotation
        await _rotateDirect(rotationUrl);
      }
    } catch (e) {
      if (e is ProxyRotationException) rethrow;
      debugPrint('[MobileProxyService] Rotation error: $e');
      throw ProxyRotationException('Rotation failed. Please try again.');
    }
  }

  static Future<void> _rotateDirect(String rotationUrl) async {
    final uri = Uri.tryParse(rotationUrl.trim());
    if (uri == null) {
      throw ProxyRotationException('Invalid rotation URL format.');
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map && data['status'] == 'success') {
        debugPrint('[MobileProxyService] Rotation successful: ${response.body}');
        return;
      }
      throw ProxyRotationException(data['message'] ?? 'Rotation failed');
    } else {
      throw ProxyRotationException('Server error: ${response.statusCode}');
    }
  }

  static Future<void> _rotateViaProxy({
    required String rotationUrl,
    required String proxyHost,
    required String username,
    required String password,
  }) async {
    // Parse the actual target from rotation URL
    // Format: http://api.sectunnel.online/rotate/1?key=xxx
    final targetUrl = rotationUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '');
    
    final proxyUrl = 'http://$proxyHost/proxy?url=http://$targetUrl';
    final credentials = base64Encode(utf8.encode('$username:$password'));

    debugPrint('[MobileProxyService] Proxy rotation URL: $proxyUrl');

    final response = await http.get(
      Uri.parse(proxyUrl),
      headers: {
        'Proxy-Authorization': 'Basic $credentials',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        debugPrint('[MobileProxyService] Proxy rotation successful');
        return;
      }
      throw ProxyRotationException(data['message'] ?? 'Rotation failed');
    } else {
      throw ProxyRotationException('Rotation failed: ${response.statusCode}');
    }
  }

  /// Check if rotation is supported for given config
  static bool supportsRotation(ProxyConfig config) {
    if (!config.isConfigured) return false;
    if (config.rotationUrl == null || config.rotationUrl!.isEmpty) return false;
    
    // Support if using direct API or proxy-tunneled
    final url = config.rotationUrl!.toLowerCase();
    return url.contains('/rotate/') && url.contains('key=');
  }

  /// Get available rotation ports (1-4)
  static List<int> getAvailablePorts() => [1, 2, 3, 4];
}