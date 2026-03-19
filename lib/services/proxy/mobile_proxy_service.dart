import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to handle rotating IPs for Mobile Proxies or API-driven proxies.
class MobileProxyService {
  /// Calls the rotation URL provided by the proxy provider.
  /// Returns `true` if the HTTP request was successful and returned status: "success".
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['status'] == 'success') {
            debugPrint('[MobileProxyService] IP rotation successful. Response: ${response.body}');
            return true;
          } else {
            debugPrint('[MobileProxyService] IP rotation failed. API status not success. Response: ${response.body}');
            return false;
          }
        } catch (e) {
          debugPrint('[MobileProxyService] IP rotation failed. Invalid JSON response. Response: ${response.body}, Parse Error: $e');
          return false;
        }
      } else {
        debugPrint('[MobileProxyService] IP rotation failed. HTTP Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[MobileProxyService] Error rotating IP: $e');
      return false;
    }
  }
}
