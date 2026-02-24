import 'package:drift/drift.dart';
import 'package:pbrowser/core/database/database.dart';
import 'package:pbrowser/models/browser_profile.dart' as model;
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/models/fingerprint_config.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [BrowserProfiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);
  
  /// Get all profiles ordered by last used (most recent first)
  Stream<List<model.BrowserProfile>> watchAllProfiles() {
    return (select(browserProfiles)
      ..orderBy([
        (p) => OrderingTerm(expression: p.lastUsedAt, mode: OrderingMode.desc),
      ]))
        .watch()
        .map((rows) => rows.map(_rowToProfile).toList());
  }
  
  /// Get all profiles as a future
  Future<List<model.BrowserProfile>> getAllProfiles() async {
    final rows = await (select(browserProfiles)
      ..orderBy([
        (p) => OrderingTerm(expression: p.lastUsedAt, mode: OrderingMode.desc),
      ]))
        .get();
    return rows.map(_rowToProfile).toList();
  }
  
  /// Get a single profile by ID
  Future<model.BrowserProfile?> getProfileById(String id) async {
    final row = await (select(browserProfiles)
      ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToProfile(row) : null;
  }
  
  /// Create a new profile
  Future<void> createProfile(model.BrowserProfile profile) async {
    await into(browserProfiles).insert(
      BrowserProfilesCompanion.insert(
        id: profile.id,
        name: profile.name,
        proxyType: profile.proxyConfig.type.toString(),
        proxyHost: Value(profile.proxyConfig.host),
        proxyPort: Value(profile.proxyConfig.port),
        proxyUsername: Value(profile.proxyConfig.username),
        proxyPassword: Value(profile.proxyConfig.password),
        proxyRotationUrl: Value(profile.proxyConfig.rotationUrl),
        fingerprintJson: profile.fingerprintConfig.toJsonString(),
        userDataFolder: profile.userDataFolder,
        createdAt: profile.createdAt,
        lastUsedAt: profile.lastUsedAt,
        tagsJson: Value(profile.tags.isEmpty ? null : profile.tagsString),
      ),
    );
  }
  
  /// Update an existing profile
  Future<void> updateProfile(model.BrowserProfile profile) async {
    await (update(browserProfiles)..where((p) => p.id.equals(profile.id)))
        .write(
      BrowserProfilesCompanion(
        name: Value(profile.name),
        proxyType: Value(profile.proxyConfig.type.toString()),
        proxyHost: Value(profile.proxyConfig.host),
        proxyPort: Value(profile.proxyConfig.port),
        proxyUsername: Value(profile.proxyConfig.username),
        proxyPassword: Value(profile.proxyConfig.password),
        proxyRotationUrl: Value(profile.proxyConfig.rotationUrl),
        fingerprintJson: Value(profile.fingerprintConfig.toJsonString()),
        userDataFolder: Value(profile.userDataFolder),
        lastUsedAt: Value(profile.lastUsedAt),
        tagsJson: Value(profile.tags.isEmpty ? null : profile.tagsString),
      ),
    );
  }
  
  /// Delete a profile
  Future<void> deleteProfile(String id) async {
    await (delete(browserProfiles)..where((p) => p.id.equals(id))).go();
  }
  
  /// Update last used timestamp
  Future<void> updateLastUsed(String id) async {
    await (update(browserProfiles)..where((p) => p.id.equals(id)))
        .write(BrowserProfilesCompanion(
      lastUsedAt: Value(DateTime.now()),
    ));
  }
  
  /// Convert database row to model
  model.BrowserProfile _rowToProfile(BrowserProfile row) {
    return model.BrowserProfile(
      id: row.id,
      name: row.name,
      proxyConfig: ProxyConfig(
        type: ProxyType.fromString(row.proxyType),
        host: row.proxyHost,
        port: row.proxyPort,
        username: row.proxyUsername,
        password: row.proxyPassword,
        rotationUrl: row.proxyRotationUrl,
      ),
      fingerprintConfig: FingerprintConfig.fromJsonString(row.fingerprintJson),
      userDataFolder: row.userDataFolder,
      createdAt: row.createdAt,
      lastUsedAt: row.lastUsedAt,
      tags: model.BrowserProfile.parseTags(row.tagsJson),
    );
  }
}
