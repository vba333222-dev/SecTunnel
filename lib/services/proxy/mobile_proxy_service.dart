import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to handle rotating IPs for Mobile Proxies or API-driven proxies.
class MobileProxyService {
  /// Calls the rotation URL provided by the proxy provider (e.g., AdsPower/Squid provider).
  /// Returns `true` if the HTTP request was successful.
  static Future<bool> rotateIp(String rotationUrl) async {
    if (rotationUrl.trim().isEmpty) {
      debugPrint('[MobileProxyService] Error: Rotation URL is empty.');
      return false;
    }

    debugPrint('[MobileProxyService] Triggering IP rotation: $rotationUrl');

    try {
      final uri = Uri.tryParse(rotationUrl.trim());
      if (uri == null) {
        debugPrint('[MobileProxyService] Error: Invalid rotation URL format.');
        return false;
      }

      // Perform a strict GET request to trigger the rotation on the provider side
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      // Usually providers return 200 OK or 2xx on success.
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[MobileProxyService] IP rotation successful. Response: \${response.body}');
        return true;
      } else {
        debugPrint('[MobileProxyService] IP rotation failed. Status: \${response.statusCode}, Body: \${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[MobileProxyService] Error rotating IP: $e');
      return false;
    }
  }
}
