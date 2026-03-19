import 'dart:convert';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/models/fingerprint_config.dart';

class BrowserProfile {
  final String id;
  final String name;
  final ProxyConfig proxyConfig;
  final FingerprintConfig fingerprintConfig;
  final String userDataFolder;
  final bool keepAliveEnabled;
  /// When true, the WebView cache and storage are wiped once on next open,
  /// then this flag is automatically reset to false.
  final bool clearBrowsingData;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final List<String> tags;

  const BrowserProfile({
    required this.id,
    required this.name,
    required this.proxyConfig,
    required this.fingerprintConfig,
    required this.userDataFolder,
    this.keepAliveEnabled = false,
    this.clearBrowsingData = false,
    required this.createdAt,
    required this.lastUsedAt,
    this.tags = const [],
  });

  /// Encodes tags to a JSON string for database storage.
  String get tagsString => jsonEncode(tags);

  /// Decodes a nullable JSON string from the database into a tag list.
  static List<String> parseTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  BrowserProfile copyWith({
    String? id,
    String? name,
    ProxyConfig? proxyConfig,
    FingerprintConfig? fingerprintConfig,
    String? userDataFolder,
    bool? keepAliveEnabled,
    bool? clearBrowsingData,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    List<String>? tags,
  }) {
    return BrowserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      proxyConfig: proxyConfig ?? this.proxyConfig,
      fingerprintConfig: fingerprintConfig ?? this.fingerprintConfig,
      userDataFolder: userDataFolder ?? this.userDataFolder,
      keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
      clearBrowsingData: clearBrowsingData ?? this.clearBrowsingData,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      tags: tags ?? this.tags,
    );
  }
}
