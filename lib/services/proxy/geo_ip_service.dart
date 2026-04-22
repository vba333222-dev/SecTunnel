import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:SecTunnel/models/proxy_config.dart';
import 'package:SecTunnel/services/proxy/http_proxy_service.dart';

class GeoIpService {
  static Future<Map<String, dynamic>?> fetchGeoData(ProxyConfig proxyConfig) async {
    if (proxyConfig.isConfigured && proxyConfig.host != null) {
      if (proxyConfig.host!.contains('sectunnel.online') || 
          proxyConfig.host!.contains('loca.lt') ||
          proxyConfig.host!.contains('trycloudflare.com')) {
        final geoData = await HttpProxyService.fetchGeoData(
          proxyHost: proxyConfig.host!,
          username: proxyConfig.username ?? 'admin',
          password: proxyConfig.password ?? 'rotator123',
        );
        if (geoData != null) return geoData;
      }

      final client = HttpClient();
      if (proxyConfig.type == ProxyType.socks5) {
        client.findProxy = (uri) => 'SOCKS5 ${proxyConfig.host}:${proxyConfig.port}';
      } else if (proxyConfig.type == ProxyType.http) {
        client.findProxy = (uri) => 'PROXY ${proxyConfig.host}:${proxyConfig.port}';
      }

      try {
        final request = await client.getUrl(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 5));
        
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          
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
      } catch (e) {
        debugPrint('[GeoIpService] Exception fetching geo data: $e');
      } finally {
        client.close();
      }
    }
    
    return null;
  }
  
  static Future<String?> fetchIpAddress(ProxyConfig proxyConfig) async {
    if (proxyConfig.isConfigured && proxyConfig.host != null) {
      if (proxyConfig.host!.contains('sectunnel.online') || 
          proxyConfig.host!.contains('loca.lt') ||
          proxyConfig.host!.contains('trycloudflare.com')) {
        final ip = await HttpProxyService.fetchIp(
          proxyHost: proxyConfig.host!,
          username: proxyConfig.username ?? 'admin',
          password: proxyConfig.password ?? 'rotator123',
        );
        if (ip != null) return ip;
      }
    }
    return null;
  }
  
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
      default: return 'en-US';
    }
  }
}