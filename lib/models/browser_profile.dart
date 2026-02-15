import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/models/fingerprint_config.dart';

class BrowserProfile {
  final String id;
  final String name;
  final ProxyConfig proxyConfig;
  final FingerprintConfig fingerprintConfig;
  final String userDataFolder;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  
  const BrowserProfile({
    required this.id,
    required this.name,
    required this.proxyConfig,
    required this.fingerprintConfig,
    required this.userDataFolder,
    required this.createdAt,
    required this.lastUsedAt,
  });
  
  BrowserProfile copyWith({
    String? id,
    String? name,
    ProxyConfig? proxyConfig,
    FingerprintConfig? fingerprintConfig,
    String? userDataFolder,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return BrowserProfile(
      id: id ?? this.id,
      name: name ?? this. name,
      proxyConfig: proxyConfig ?? this.proxyConfig,
      fingerprintConfig: fingerprintConfig ?? this.fingerprintConfig,
      userDataFolder: userDataFolder ?? this.userDataFolder,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
