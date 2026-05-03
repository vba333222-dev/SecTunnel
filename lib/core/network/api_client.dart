import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sec_tunnel/core/logging/logger.dart';

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
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://35.198.231.6:6000',
      defaultHeaders: {
        'Authorization': dotenv.env['API_AUTH_KEY'] ?? 'secret123',
      },
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

  /// GET request to a relative path on the baseUrl.
  /// Returns decoded JSON map.
  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    _log.info(LogTag.network, 'GET $path');
    final sw = Stopwatch()..start();
    try {
      final response = await _client
          .get(uri, headers: defaultHeaders)
          .timeout(timeout);
      sw.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.info(LogTag.network, 'GET $path → ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _log.error(LogTag.network, 'GET $path → HTTP ${response.statusCode}');
      throw ApiException.fromStatusCode(response.statusCode);
    } on TimeoutException {
      _log.error(LogTag.network, 'GET $path → TIMEOUT (${sw.elapsedMilliseconds}ms)');
      throw const ApiException(
        type: ApiErrorType.timeout,
        message: 'Request timed out',
      );
    } on SocketException {
      _log.error(LogTag.network, 'GET $path → UNREACHABLE');
      throw const ApiException(
        type: ApiErrorType.networkUnreachable,
        message: 'Network unreachable',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _log.error(LogTag.network, 'GET $path → ${e.runtimeType}');
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
    } on SocketException catch (e) {
      _log.error(LogTag.network, 'GET $shortUrl → NETWORK_ERROR: $e');
      throw ApiException(
        type: ApiErrorType.networkUnreachable,
        message: 'Network unreachable: ${e.message}',
      );
    } catch (e) {
      _log.error(LogTag.network, 'GET $shortUrl → UNKNOWN_ERROR: $e');
      throw ApiException(
        type: ApiErrorType.unknown,
        message: 'Unknown error: $e',
      );
    }
  }

  /// Same as [getJson], but explicitly goes through the configured proxy.
  /// Used for IP verification.
  Future<Map<String, dynamic>> getJsonThroughProxy(String url) async {
    final uri = Uri.parse(url);
    final proxyHost = dotenv.env['PROXY_HOST'] ?? '127.0.0.1';
    final proxyPort = int.tryParse(dotenv.env['PROXY_PORT'] ?? '') ?? 3128;

    _log.info(LogTag.network, 'Proxy GET $url via $proxyHost:$proxyPort');

    try {
      // Use HttpClient with explicit proxy for verification
      final ioClient = HttpClient();
      ioClient.findProxy = (uri) => 'PROXY $proxyHost:$proxyPort';
      
      // Basic Auth if needed
      final user = dotenv.env['PROXY_USER'];
      final pass = dotenv.env['PROXY_PASS'];
      if (user != null && pass != null) {
        ioClient.authenticateProxy = (String host, int port, String scheme, String? realm) {
          ioClient.addProxyCredentials(host, port, realm ?? '', HttpClientBasicCredentials(user, pass));
          return Future.value(true);
        };
      }

      final request = await ioClient.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
      throw ApiException.fromStatusCode(response.statusCode);
    } catch (e) {
      _log.error(LogTag.network, 'Proxy GET error: $e');
      throw ApiException(
        message: 'Proxy GET failed: $e',
        type: ApiErrorType.unknown,
      );
    }
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _client.close();
    _instance = null;
  }
}
