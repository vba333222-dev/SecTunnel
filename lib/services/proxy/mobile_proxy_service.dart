import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProxyRotationException implements Exception {
  final String message;
  ProxyRotationException(this.message);
  @override
  String toString() => message;
}

/// Service to handle rotating IPs for Mobile Proxies or API-driven proxies.
class MobileProxyService {
  /// Calls the rotation URL provided by the proxy provider.
  /// Throws a [ProxyRotationException] if the HTTP request was unsuccessful or timed out.
  static Future<void> rotateIp(String rotationUrl) async {
    if (rotationUrl.trim().isEmpty) {
      throw ProxyRotationException('Oops! The rotation URL seems to be missing. Please check your proxy settings.');
    }

    debugPrint('[MobileProxyService] Triggering IP rotation: $rotationUrl');

    try {
      final uri = Uri.tryParse(rotationUrl.trim());
      if (uri == null) {
        throw ProxyRotationException("We couldn't format the rotation request properly. Please verify the URL.");
      }

      // Perform a strict GET request to trigger the rotation on the provider side
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['status'] == 'success') {
            debugPrint('[MobileProxyService] IP rotation successful. Response: ${response.body}');
            return;
          } else {
            throw ProxyRotationException('The rotation request was sent, but the provider did not return a success signal.');
          }
        } catch (e) {
          throw ProxyRotationException('We received an unexpected response from the proxy rotation server. Please try again.');
        }
      } else {
        throw ProxyRotationException('The rotation server responded with an error (Code ${response.statusCode}). Please try again later.');
      }
    } on TimeoutException {
      throw ProxyRotationException('Oops! The proxies seem unreachable right now. Please try rotating the IP again or check the device connection.');
    } catch (e) {
      debugPrint('[MobileProxyService] Error rotating IP: $e');
      if (e is ProxyRotationException) rethrow;
      throw ProxyRotationException('Oops! An unexpected error occurred while rotating the IP. Please check your network connection.');
    }
  }
}
