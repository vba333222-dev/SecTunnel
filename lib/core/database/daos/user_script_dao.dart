import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:SecTunnel/core/database/database.dart';
import 'package:SecTunnel/models/user_script.dart';

class UserScriptDao {
  final AppDatabase _db;
  
  UserScriptDao(this._db);
  
  Future<List<UserScript>> getScriptsByProfile(String profileId) async {
    final db = await _db.database;
    final results = await db.query(
      'user_scripts',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
    return results.map(_mapToDomain).toList();
  }
  
  Future<List<UserScript>> getActiveScriptsByProfile(String profileId) async {
    final db = await _db.database;
    final results = await db.query(
      'user_scripts',
      where: 'profile_id = ? AND is_active = 1',
      whereArgs: [profileId],
    );
    return results.map(_mapToDomain).toList();
  }
  
  Future<void> createScript(UserScript script) async {
    final db = await _db.database;
    await db.insert(
      'user_scripts',
      _mapFromDomain(script),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> updateScript(UserScript script) async {
    final db = await _db.database;
    await db.update(
      'user_scripts',
      _mapFromDomain(script),
      where: 'id = ?',
      whereArgs: [script.id],
    );
  }
  
  Future<void> deleteScript(String id) async {
    final db = await _db.database;
    await db.delete(
      'user_scripts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> toggleScriptActive(String id, bool isActive) async {
    final db = await _db.database;
    await db.update(
      'user_scripts',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  UserScript _mapToDomain(Map<String, dynamic> row) {
    return UserScript(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      name: row['name'] as String,
      urlPattern: row['url_pattern'] as String,
      jsPayload: row['js_payload'] as String,
      isActive: (row['is_active'] as int) == 1,
      runAt: row['run_at'] as String? ?? 'document_idle',
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
  
  Map<String, dynamic> _mapFromDomain(UserScript script) {
    return {
      'id': script.id,
      'profile_id': script.profileId,
      'name': script.name,
      'url_pattern': script.urlPattern,
      'js_payload': script.jsPayload,
      'is_active': script.isActive ? 1 : 0,
      'run_at': script.runAt,
      'created_at': script.createdAt.millisecondsSinceEpoch,
      'updated_at': script.updatedAt.millisecondsSinceEpoch,
    };
  }
}