import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:SecTunnel/models/proxy_config.dart';

/// Service to fetch Geolocation and Timezone data matching the active external IP.
class GeoIpService {
  /// Fetches Geo-IP data routing through the provided ProxyConfig.
  /// If [proxyConfig] is not configured, it fetches the local network's Geo-IP.
  static Future<Map<String, dynamic>?> fetchGeoData(ProxyConfig proxyConfig) async {
    final client = HttpClient();
    
    // Explicitly route this Dart HttpClient request through the given proxy.
    // This is crucial; otherwise, we'd get the geolocation of the local PC instead of the proxy output node.
    if (proxyConfig.isConfigured && proxyConfig.host != null && proxyConfig.port != null) {
      if (proxyConfig.type == ProxyType.socks5) {
        client.findProxy = (uri) => 'SOCKS5 ${proxyConfig.host}:${proxyConfig.port}';
      } else if (proxyConfig.type == ProxyType.http) {
        client.findProxy = (uri) => 'PROXY ${proxyConfig.host}:${proxyConfig.port}';
      }
    }

    try {
      // Use ip-api's JSON endpoint. It returns lat, lon, timezone, countryCode.
      final request = await client.getUrl(Uri.parse('http://ip-api.com/json'))
        .timeout(const Duration(seconds: 5));
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (data['status'] == 'success') {
          return {
            'latitude': (data['lat'] as num?)?.toDouble() ?? 0.0,
            'longitude': (data['lon'] as num?)?.toDouble() ?? 0.0,
            'timezone': data['timezone'] as String? ?? 'Asia/Jakarta',
            'countryCode': data['countryCode'] as String? ?? 'US',
          };
        }
      }
    } catch (e) {
      debugPrint('[GeoIpService] Exception fetching geo data: $e');
    } finally {
      client.close();
    }
    
    return null;
  }
  
  /// Helper to convert a country code (e.g. US, ID, GB) to a standard BCP 47 language tag (en-US).
  /// This helps dynamic language spoofing based on IP.
  static String countryCodeToLanguage(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'US': return 'en-US';
      case 'GB': return 'en-GB';
      case 'CA': return 'en-CA';
      case 'AU': return 'en-AU';
      case 'ID': return 'id-ID';
      case 'SG': return 'en-SG';
      case 'MY': return 'ms-MY';
      case 'FR': return 'fr-FR';
      case 'DE': return 'de-DE';
      case 'JP': return 'ja-JP';
      case 'CN': return 'zh-CN';
      case 'BR': return 'pt-BR';
      case 'ES': return 'es-ES';
      case 'MX': return 'es-MX';
      case 'RU': return 'ru-RU';
      case 'IN': return 'en-IN';
      default: return 'en-US'; // Fallback
    }
  }
}
