import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:SecTunnel/models/proxy_config.dart';

class ProxyApiException implements Exception {
  final String message;
  ProxyApiException(this.message);
  @override
  String toString() => message;
}

class HttpProxyService {
  static String? _cachedIp;
  static DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(seconds: 30);

  static Future<String?> fetchExternalIp({
    required String proxyHost,
    required String username,
    required String password,
  }) async {
    if (_cachedIp != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
        return _cachedIp;
      }
    }

    final proxyUrl = 'http://$proxyHost/proxy?url=http://ifconfig.me';
    final credentials = base64Encode(utf8.encode('$username:$password'));

    try {
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Proxy-Authorization': 'Basic $credentials',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final ip = response.body.trim();
        if (_isValidIp(ip)) {
          _cachedIp = ip;
          _lastFetch = DateTime.now();
          debugPrint('[HttpProxyService] IP fetched: $ip');
          return ip;
        }
      }

      debugPrint('[HttpProxyService] Failed - status: ${response.statusCode}, body: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[HttpProxyService] Error: $e');
      return null;
    }
  }

  static Future<String?> fetchIp({
    required String proxyHost,
    required String username,
    required String password,
  }) async {
    return await fetchExternalIp(
      proxyHost: proxyHost,
      username: username,
      password: password,
    );
  }

  static bool _isValidIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  static Future<Map<String, dynamic>?> fetchGeoData({
    required String proxyHost,
    required String username,
    required String password,
  }) async {
    final proxyUrl = 'http://$proxyHost/proxy?url=http://ip-api.com/json';
    final credentials = base64Encode(utf8.encode('$username:$password'));

    try {
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Proxy-Authorization': 'Basic $credentials',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return {
            'ip': data['query'] as String? ?? '',
            'latitude': (data['lat'] as num?)?.toDouble() ?? 0.0,
            'longitude': (data['lon'] as num?)?.toDouble() ?? 0.0,
            'timezone': data['timezone'] as String? ?? 'Asia/Jakarta',
            'countryCode': data['countryCode'] as String? ?? 'US',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('[HttpProxyService] Geo fetch error: $e');
      return null;
    }
  }

  static Future<String> fetchWithProxy({
    required String targetUrl,
    required String proxyHost,
    required String username,
    required String password,
  }) async {
    final proxyUrl = 'http://$proxyHost/proxy?url=${Uri.encodeComponent(targetUrl)}';
    final credentials = base64Encode(utf8.encode('$username:$password'));

    final response = await http.get(
      Uri.parse(proxyUrl),
      headers: {
        'Proxy-Authorization': 'Basic $credentials',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ProxyApiException('Request failed with status: ${response.statusCode}');
    }
  }
}