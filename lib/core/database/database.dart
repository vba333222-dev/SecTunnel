import 'package:drift/drift.dart';
import 'package:pbrowser/core/database/daos/user_script_dao.dart';

part 'database.g.dart';

/// Browser profile table definition
class BrowserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  
  // Proxy configuration
  TextColumn get proxyType => text()(); // 'none', 'http', 'socks5'
  TextColumn get proxyHost => text().nullable()();
  IntColumn get proxyPort => integer().nullable()();
  TextColumn get proxyUsername => text().nullable()();
  TextColumn get proxyPassword => text().nullable()();
  TextColumn get proxyRotationUrl => text().nullable()();
  
  // Fingerprint configuration (stored as JSON)
  TextColumn get fingerprintJson => text()();
  
  // Session isolation
  TextColumn get userDataFolder => text()();
  
  // Background Keep-Alive
  BoolColumn get keepAliveEnabled => boolean().withDefault(const Constant(false))();
  
  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime()();

  // Tags (stored as JSON array string, e.g. '["Airdrop","BCA"]')
  TextColumn get tagsJson => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// UserScripts table for Mini-Tampermonkey functionality
@DataClassName('UserScriptEntity')
class UserScripts extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()(); // Foreign key to BrowserProfiles
  TextColumn get name => text()();
  TextColumn get urlPattern => text()(); // Regex string
  TextColumn get jsPayload => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get runAt => text().withDefault(const Constant('document_idle'))(); // document_start or document_idle
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [BrowserProfiles, UserScripts], daos: [UserScriptDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  
  @override
  UserScriptDao get userScriptDao => UserScriptDao(this);
  
  @override
  int get schemaVersion => 3;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      
      // Create index for faster sorting by last used
      await customStatement(
        'CREATE INDEX idx_profiles_last_used ON browser_profiles(last_used_at DESC)'
      );
      
      // Index for userscripts by profile
      await customStatement(
        'CREATE INDEX idx_userscripts_profile ON user_scripts(profile_id)'
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(userScripts);
        await customStatement(
          'CREATE INDEX idx_userscripts_profile ON user_scripts(profile_id)'
        );
        await m.addColumn(browserProfiles, browserProfiles.proxyRotationUrl);
      }
      if (from < 3) {
        await m.addColumn(browserProfiles, browserProfiles.keepAliveEnabled);
        await m.addColumn(browserProfiles, browserProfiles.tagsJson);
      }
    },
  );
}
