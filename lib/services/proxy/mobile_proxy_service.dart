import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:SecTunnel/models/proxy_config.dart';
import 'package:SecTunnel/models/ip_info.dart';

class ProxyRotationException implements Exception {
  final String message;
  ProxyRotationException(this.message);
  @override
  String toString() => message;
}

class MobileProxyService {
  static const String _apiHost = '35.198.231.6:6000';
  static const String _authHeader = 'secret123';
  static const Duration _rotateTimeout = Duration(seconds: 30);
  static const Duration _ipTimeout = Duration(seconds: 8);

  static Future<IpInfo> getIpInfo() async {
    try {
      final sw = Stopwatch()..start();
      final response = await http.get(Uri.parse('http://ip-api.com/json/?fields=status,message,country,regionName,isp,proxy,hosting,query')).timeout(_ipTimeout);
      sw.stop();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return IpInfo.fromJson(data, latency: sw.elapsedMilliseconds);
        }
      }
      throw ProxyRotationException('validation_failed');
    } catch (_) {
      throw ProxyRotationException('validation_failed');
    }
  }

  static Future<void> rotateIp() async {
    final uri = Uri.parse('http://$_apiHost/rotate');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Authorization': _authHeader},
      ).timeout(_rotateTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      
      throw ProxyRotationException('Rotation failed');
    } on TimeoutException {
      throw ProxyRotationException('Server timeout');
    } on SocketException {
      throw ProxyRotationException('Tunnel unreachable');
    } catch (e) {
      if (e is ProxyRotationException) rethrow;
      throw ProxyRotationException('Rotation failed');
    }
  }

  static bool supportsRotation(ProxyConfig config) {
    if (!config.isConfigured) return false;
    return true;
  }

  static List<int> getAvailablePorts() => [1, 2, 3, 4];
}
