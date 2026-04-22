import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:SecTunnel/core/database/database.dart';
import 'package:SecTunnel/models/browser_profile.dart' as model;
import 'package:SecTunnel/models/proxy_config.dart';
import 'package:SecTunnel/models/fingerprint_config.dart';

class ProfileDao {
  final AppDatabase _db;
  
  ProfileDao(this._db);
  
  Stream<List<model.BrowserProfile>> watchAllProfiles() {
    debugPrint('[ProfileDao] watchAllProfiles called');
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => getAllProfiles());
  }
  
  Future<List<model.BrowserProfile>> getAllProfiles() async {
    debugPrint('[ProfileDao] getAllProfiles called');
    try {
      final db = await _db.database;
      final results = await db.query(
        'browser_profiles',
        orderBy: 'last_used_at DESC',
      );
      debugPrint('[ProfileDao] getAllProfiles got ${results.length} rows');
      return results.map(_rowToProfile).toList();
    } catch (e, st) {
      debugPrint('[ProfileDao] getAllProfiles error: $e');
      debugPrint('[ProfileDao] Stack: $st');
      return [];
    }
  }
  
  Future<model.BrowserProfile?> getProfileById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'browser_profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _rowToProfile(results.first);
  }
  
  Future<void> createProfile(model.BrowserProfile profile) async {
    final db = await _db.database;
    await db.insert(
      'browser_profiles',
      _profileToMap(profile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> updateProfile(model.BrowserProfile profile) async {
    final db = await _db.database;
    await db.update(
      'browser_profiles',
      _profileToMap(profile),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }
  
  Future<void> deleteProfile(String id) async {
    final db = await _db.database;
    await db.delete(
      'browser_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> updateLastUsed(String id) async {
    final db = await _db.database;
    await db.update(
      'browser_profiles',
      {'last_used_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Map<String, dynamic> _profileToMap(model.BrowserProfile profile) {
    final proxy = profile.proxyConfig;
    return {
      'id': profile.id,
      'name': profile.name,
      'proxy_type': proxy.type.toString(),
      'proxy_host': proxy.hostField,
      'proxy_port': proxy.port,
      'proxy_username': proxy.usernameField,
      'proxy_password': proxy.passwordField,
      'proxy_rotation_url': proxy.rotationUrlField,
      'fingerprint_json': profile.fingerprintConfig.toJsonString(),
      'user_data_folder': profile.userDataFolder,
      'keep_alive_enabled': profile.keepAliveEnabled ? 1 : 0,
      'clear_browsing_data': profile.clearBrowsingData ? 1 : 0,
      'created_at': profile.createdAt.millisecondsSinceEpoch,
      'last_used_at': profile.lastUsedAt.millisecondsSinceEpoch,
      'tags_json': profile.tags.isEmpty ? null : profile.tagsString,
    };
  }
  
  model.BrowserProfile _rowToProfile(Map<String, dynamic> row) {
    return model.BrowserProfile(
      id: row['id'] as String,
      name: row['name'] as String,
      proxyConfig: ProxyConfig(
        type: ProxyType.fromString(row['proxy_type'] as String),
        host: row['proxy_host'] as String?,
        port: row['proxy_port'] as int?,
        username: row['proxy_username'] as String?,
        password: row['proxy_password'] as String?,
        rotationUrl: row['proxy_rotation_url'] as String?,
      ),
      fingerprintConfig: FingerprintConfig.fromJsonString(
        row['fingerprint_json'] as String,
      ),
      userDataFolder: row['user_data_folder'] as String,
      keepAliveEnabled: (row['keep_alive_enabled'] as int) == 1,
      clearBrowsingData: (row['clear_browsing_data'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(row['last_used_at'] as int),
      tags: model.BrowserProfile.parseTags(row['tags_json'] as String?),
    );
  }
}