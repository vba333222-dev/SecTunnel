import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:SecTunnel/core/logging/logger.dart';

// ─── Structured Error Types ─────────────────────────────────────
enum ApiErrorType {
  timeout,
  networkUnreachable,
  unauthorized,
  serverError,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromStatusCode(int code) {
    if (code == 401 || code == 403) {
      return ApiException(
        type: ApiErrorType.unauthorized,
        message: 'Unauthorized',
        statusCode: code,
      );
    }
    if (code >= 500) {
      return ApiException(
        type: ApiErrorType.serverError,
        message: 'Server error ($code)',
        statusCode: code,
      );
    }
    return ApiException(
      type: ApiErrorType.unknown,
      message: 'HTTP $code',
      statusCode: code,
    );
  }

  /// Maps error type to a human-readable UI message.
  String get displayMessage {
    switch (type) {
      case ApiErrorType.timeout:
        return 'Server timeout';
      case ApiErrorType.networkUnreachable:
        return 'Tunnel unreachable';
      case ApiErrorType.unauthorized:
        return 'Unauthorized';
      case ApiErrorType.serverError:
        return 'Server error';
      case ApiErrorType.unknown:
        return message;
    }
  }

  @override
  String toString() => '[ApiException] $type: $message';
}

// ─── Centralized HTTP Client ────────────────────────────────────
class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final AppLogger _log = AppLogger.instance;

  ApiClient._({
    required this.baseUrl,
    required this.defaultHeaders,
    required this.timeout,
    required http.Client client,
  }) : _client = client;

  /// Singleton instance for the rotation API.
  static ApiClient? _instance;

  static ApiClient get instance {
    _instance ??= ApiClient._(
      baseUrl: 'http://35.198.231.6:6000',
      defaultHeaders: const {'Authorization': 'secret123'},
      timeout: const Duration(seconds: 30),
      client: http.Client(),
    );
    return _instance!;
  }

  /// POST request. Returns raw [http.Response].
  /// Throws [ApiException] on any failure.
  Future<http.Response> post(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    _log.info(LogTag.network, 'POST $path');
    final sw = Stopwatch()..start();
    try {
      final response = await _client
          .post(uri, headers: defaultHeaders)
          .timeout(timeout);
      sw.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.info(LogTag.network, 'POST $path → ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
        return response;
      }
      _log.error(LogTag.network, 'POST $path → HTTP ${response.statusCode}');
      throw ApiException.fromStatusCode(response.statusCode);
    } on TimeoutException {
      _log.error(LogTag.network, 'POST $path → TIMEOUT (${sw.elapsedMilliseconds}ms)');
      throw const ApiException(
        type: ApiErrorType.timeout,
        message: 'Request timed out',
      );
    } on SocketException {
      _log.error(LogTag.network, 'POST $path → UNREACHABLE');
      throw const ApiException(
        type: ApiErrorType.networkUnreachable,
        message: 'Network unreachable',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _log.error(LogTag.network, 'POST $path → ${e.runtimeType}');
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.toString(),
      );
    }
  }

  /// GET request to any external URL (for IP info APIs).
  /// Returns decoded JSON map.
  /// Throws [ApiException] on any failure.
  Future<Map<String, dynamic>> getJson(
    String url, {
    Duration? requestTimeout,
  }) async {
    final uri = Uri.parse(url);
    final effectiveTimeout = requestTimeout ?? timeout;
    final shortUrl = uri.host + uri.path;
    _log.info(LogTag.network, 'GET $shortUrl');
    final sw = Stopwatch()..start();
    try {
      final response = await _client
          .get(uri)
          .timeout(effectiveTimeout);
      sw.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.info(LogTag.network, 'GET $shortUrl → ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _log.error(LogTag.network, 'GET $shortUrl → HTTP ${response.statusCode}');
      throw ApiException.fromStatusCode(response.statusCode);
    } on TimeoutException {
      _log.error(LogTag.network, 'GET $shortUrl → TIMEOUT (${sw.elapsedMilliseconds}ms)');
      throw const ApiException(
        type: ApiErrorType.timeout,
        message: 'Request timed out',
      );
    } on SocketException {
      _log.error(LogTag.network, 'GET $shortUrl → UNREACHABLE');
      throw const ApiException(
        type: ApiErrorType.networkUnreachable,
        message: 'Network unreachable',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _log.error(LogTag.network, 'GET $shortUrl → ${e.runtimeType}');
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.toString(),
      );
    }
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _client.close();
    _instance = null;
  }
}
