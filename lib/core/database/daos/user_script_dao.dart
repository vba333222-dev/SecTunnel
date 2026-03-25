import 'package:drift/drift.dart';
import 'package:SecTunnel/core/database/database.dart';
import 'package:SecTunnel/models/user_script.dart';

part 'user_script_dao.g.dart';

@DriftAccessor(tables: [UserScripts])
class UserScriptDao extends DatabaseAccessor<AppDatabase> with _$UserScriptDaoMixin {
  UserScriptDao(super.db);

  UserScript _mapToDomain(UserScriptEntity data) {
    return UserScript(
      id: data.id,
      profileId: data.profileId,
      name: data.name,
      urlPattern: data.urlPattern,
      jsPayload: data.jsPayload,
      isActive: data.isActive,
      runAt: data.runAt,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  UserScriptsCompanion _mapFromDomain(UserScript domain) {
    return UserScriptsCompanion(
      id: Value(domain.id),
      profileId: Value(domain.profileId),
      name: Value(domain.name),
      urlPattern: Value(domain.urlPattern),
      jsPayload: Value(domain.jsPayload),
      isActive: Value(domain.isActive),
      runAt: Value(domain.runAt),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
    );
  }

  /// Get all scripts for a profile
  Future<List<UserScript>> getScriptsByProfile(String profileId) async {
    final query = select(userScripts)..where((t) => t.profileId.equals(profileId));
    final result = await query.get();
    return result.map(_mapToDomain).toList();
  }

  /// Get active scripts for a profile
  Future<List<UserScript>> getActiveScriptsByProfile(String profileId) async {
    final query = select(userScripts)
      ..where((t) => t.profileId.equals(profileId) & t.isActive.equals(true));
    final result = await query.get();
    return result.map(_mapToDomain).toList();
  }

  /// Create a new script
  Future<void> createScript(UserScript script) async {
    await into(userScripts).insert(_mapFromDomain(script));
  }

  /// Update an existing script
  Future<void> updateScript(UserScript script) async {
    await update(userScripts).replace(_mapFromDomain(script));
  }

  /// Delete a script
  Future<void> deleteScript(String id) async {
    await (delete(userScripts)..where((t) => t.id.equals(id))).go();
  }

  /// Toggle script active state
  Future<void> toggleScriptActive(String id, bool isActive) async {
    await (update(userScripts)..where((t) => t.id.equals(id))).write(
      UserScriptsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
