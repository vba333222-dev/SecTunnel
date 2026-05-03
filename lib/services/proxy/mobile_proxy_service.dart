import 'dart:async';
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
  static const Duration _ipInfoTimeout = Duration(seconds: 8);
  static const String _ipInfoUrl =
      'http://ip-api.com/json/?fields=status,message,country,regionName,isp,proxy,hosting,query';

  final ApiClient _api;

  MobileProxyService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  /// Fetches current public IP info from ip-api.com.
  /// Measures round-trip latency.
  Future<IpInfo> getIpInfo() async {
    try {
      final sw = Stopwatch()..start();
      final data = await _api.getJson(
        _ipInfoUrl,
        requestTimeout: _ipInfoTimeout,
      );
      sw.stop();

      if (data['status'] == 'success') {
        return IpInfo.fromJson(data, latency: sw.elapsedMilliseconds);
      }
      throw const RotationException(
        RotationErrorType.validationFailed,
        'IP API returned non-success status',
      );
    } on RotationException {
      rethrow;
    } on ApiException catch (e) {
      throw RotationException(
        _mapApiError(e.type),
        e.message,
      );
    } catch (e) {
      throw RotationException(
        RotationErrorType.validationFailed,
        e.toString(),
      );
    }
  }

  /// Sends a POST /rotate to the relay VPS.
  /// Returns void on success. Throws [RotationException] on failure.
  Future<void> rotateIp() async {
    try {
      await _api.post('/rotate');
    } on ApiException catch (e) {
      throw RotationException(
        _mapApiError(e.type),
        e.message,
      );
    } catch (e) {
      if (e is RotationException) rethrow;
      throw RotationException(
        RotationErrorType.rotationFailed,
        e.toString(),
      );
    }
  }

  /// Utility: whether a given proxy config supports rotation.
  bool supportsRotation(ProxyConfig config) => config.isConfigured;

  /// Available modem port indices.
  List<int> getAvailablePorts() => const [1, 2, 3, 4];

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
