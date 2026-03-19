import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ProxyType {
  none,
  http,
  socks5;
  
  static ProxyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'http':
        return ProxyType.http;
      case 'socks5':
        return ProxyType.socks5;
      default:
        return ProxyType.none;
    }
  }
  
  @override
  String toString() {
    switch (this) {
      case ProxyType.http:
        return 'http';
      case ProxyType.socks5:
        return 'socks5';
      case ProxyType.none:
        return 'none';
    }
  }
}

class ProxyConfig {
  final ProxyType type;
  final bool useSystemProxyPool;
  final String? _host;
  final int? port;
  final String? _username;
  final String? _password;
  final String? _rotationUrl;
  
  const ProxyConfig({
    required this.type,
    this.useSystemProxyPool = false,
    String? host,
    this.port,
    String? username,
    String? password,
    String? rotationUrl,
  })  : _host = host,
        _username = username,
        _password = password,
        _rotationUrl = rotationUrl;
  
  const ProxyConfig.none()
      : type = ProxyType.none,
        useSystemProxyPool = false,
        _host = null,
        port = null,
        _username = null,
        _password = null,
        _rotationUrl = null;
  
  String? get host => useSystemProxyPool ? dotenv.env['PROXY_HOST'] : _host;
  String? get username => useSystemProxyPool ? dotenv.env['PROXY_USER'] : _username;
  String? get password => useSystemProxyPool ? dotenv.env['PROXY_PASS'] : _password;
  
  String? get rotationUrl {
    if (useSystemProxyPool) {
      final baseUrl = dotenv.env['ROTATION_API_BASE_URL'];
      final key = dotenv.env['ROTATION_API_KEY'];
      if (baseUrl != null && baseUrl.isNotEmpty) {
        return '$baseUrl/rotate/$port?key=$key';
      }
      return null;
    }
    return _rotationUrl;
  }

  bool get isConfigured => type != ProxyType.none && host != null && port != null;

  /// `true` when both [username] and [password] are non-null and non-empty.
  bool get hasCredentials =>
      username != null &&
      username!.isNotEmpty &&
      password != null &&
      password!.isNotEmpty;

  /// Returns the `Proxy-Authorization` header **value** (everything after the
  /// colon) when credentials are present, e.g.:
  ///   `"Basic YWRtaW46cm90YXRvcjEyMw=="`
  ///
  /// Returns `null` when [hasCredentials] is `false`.
  String? get basicAuthHeader {
    if (!hasCredentials) return null;
    final encoded = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $encoded';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'useSystemProxyPool': useSystemProxyPool,
      'host': _host,
      'port': port,
      'username': _username,
      'password': _password,
      'rotationUrl': _rotationUrl,
    };
  }
  
  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      type: ProxyType.fromString(json['type'] as String? ?? 'none'),
      useSystemProxyPool: json['useSystemProxyPool'] as bool? ?? false,
      host: json['host'] as String?,
      port: json['port'] as int?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      rotationUrl: json['rotationUrl'] as String?,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory ProxyConfig.fromJsonString(String jsonString) {
    return ProxyConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
  
  ProxyConfig copyWith({
    ProxyType? type,
    bool? useSystemProxyPool,
    String? host,
    int? port,
    String? username,
    String? password,
    String? rotationUrl,
  }) {
    return ProxyConfig(
      type: type ?? this.type,
      useSystemProxyPool: useSystemProxyPool ?? this.useSystemProxyPool,
      host: host ?? this._host,
      port: port ?? this.port,
      username: username ?? _username,
      password: password ?? _password,
      rotationUrl: rotationUrl ?? _rotationUrl,
    );
  }
}
