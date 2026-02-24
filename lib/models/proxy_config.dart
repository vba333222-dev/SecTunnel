import 'dart:convert';

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
  final String? host;
  final int? port;
  final String? username;
  final String? password;
  final String? rotationUrl;
  
  const ProxyConfig({
    required this.type,
    this.host,
    this.port,
    this.username,
    this.password,
    this.rotationUrl,
  });
  
  const ProxyConfig.none()
      : type = ProxyType.none,
        host = null,
        port = null,
        username = null,
        password = null,
        rotationUrl = null;
  
  bool get isConfigured => type != ProxyType.none && host != null && port != null;
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'rotationUrl': rotationUrl,
    };
  }
  
  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      type: ProxyType.fromString(json['type'] as String? ?? 'none'),
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
    String? host,
    int? port,
    String? username,
    String? password,
    String? rotationUrl,
  }) {
    return ProxyConfig(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      rotationUrl: rotationUrl ?? this.rotationUrl,
    );
  }
}
