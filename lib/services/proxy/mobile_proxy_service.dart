import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sec_tunnel/core/network/api_client.dart';
import 'package:sec_tunnel/models/proxy_config.dart';
import 'package:sec_tunnel/models/ip_info.dart';

// ─── Rotation-Specific Error ────────────────────────────────────
enum RotationErrorType {
  validationFailed,
  ipNotChanged,
  serverTimeout,
  tunnelUnreachable,
  rotationFailed,
}

class RotationException implements Exception {
  final RotationErrorType type;
  final String message;

  const RotationException(this.type, this.message);

  /// Human-readable message for UI display.
  String get displayMessage {
    switch (type) {
      case RotationErrorType.validationFailed:
        return 'Validation failed';
      case RotationErrorType.ipNotChanged:
        return 'IP not changed';
      case RotationErrorType.serverTimeout:
        return 'Server timeout';
      case RotationErrorType.tunnelUnreachable:
        return 'Tunnel unreachable';
      case RotationErrorType.rotationFailed:
        return 'Rotation failed';
    }
  }

  @override
  String toString() => '[RotationException] ${type.name}: $message';
}

// ─── Service ────────────────────────────────────────────────────
/// Stateless service layer between ModemRotatorService and ApiClient.
/// Handles only network calls — no state, no UI, no retry logic.
class MobileProxyService {
  // AppLogger removed as unused
  final ApiClient _api;

  MobileProxyService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  /// Fetches current public IP via the proxy with fallback support.
  /// IMPORTANT: Uses HTTPS and PROXY authentication to avoid blockages.
  Future<IpInfo> getIpInfo() async {
    final List<String> endpoints = [
      'https://api.ipify.org?format=json',
      'https://ipinfo.io/json',
      'https://api.myip.com',
    ];

    Object? lastError;

    for (final url in endpoints) {
      try {
        final json = await _api.getJsonThroughProxy(url);
        
        // Extract IP based on different API response structures
        String? ip;
        if (url.contains('ipify')) {
          ip = json['ip'] as String?;
        } else if (url.contains('ipinfo')) {
          ip = json['ip'] as String?;
        } else if (url.contains('myip')) {
          ip = json['ip'] as String?;
        }

        if (ip != null && ip.isNotEmpty) {
          return IpInfo.fromJson({
            'query': ip,
            'status': 'success',
            'country': json['country'] ?? 'Unknown',
            'isp': json['org'] ?? json['isp'] ?? 'Unknown',
          });
        }
      } catch (e) {
        lastError = e;
        // Continue to next fallback
      }
    }

    // If all fail
    throw RotationException(
      RotationErrorType.validationFailed,
      'All IP verification endpoints failed. Last error: $lastError',
    );
  }

  /// Sends a POST /rotate to the relay VPS.
  Future<void> rotateIp() async {
    try {
      final endpoint = dotenv.env['API_ROTATE_ENDPOINT'] ?? '/rotate';
      await _api.post(endpoint);
    } on ApiException catch (e) {
      throw RotationException(
        _mapApiError(e.type),
        e.message,
      );
    } catch (e) {
      throw RotationException(
        RotationErrorType.rotationFailed,
        e.toString(),
      );
    }
  }

  /// Polls the backend for the current rotation status.
  Future<Map<String, dynamic>> getRotationStatus() async {
    try {
      final endpoint = dotenv.env['API_STATUS_ENDPOINT'] ?? '/status';
      return await _api.get(endpoint);
    } on ApiException catch (e) {
      throw RotationException(
        _mapApiError(e.type),
        e.message,
      );
    } catch (e) {
      throw RotationException(
        RotationErrorType.rotationFailed,
        e.toString(),
      );
    }
  }

  /// Utility: whether a given proxy config supports rotation.
  bool supportsRotation(ProxyConfig config) => config.isConfigured;

  // Maps ApiException types to RotationException types.
  RotationErrorType _mapApiError(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.timeout:
        return RotationErrorType.serverTimeout;
      case ApiErrorType.networkUnreachable:
        return RotationErrorType.tunnelUnreachable;
      case ApiErrorType.unauthorized:
      case ApiErrorType.serverError:
      case ApiErrorType.unknown:
        return RotationErrorType.rotationFailed;
    }
  }
}
