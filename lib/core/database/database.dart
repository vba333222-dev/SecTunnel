import 'package:drift/drift.dart';

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
  
  // Fingerprint configuration (stored as JSON)
  TextColumn get fingerprintJson => text()();
  
  // Session isolation
  TextColumn get userDataFolder => text()();
  
  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [BrowserProfiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      
      // Create index for faster sorting by last used
      await customStatement(
        'CREATE INDEX idx_profiles_last_used ON browser_profiles(last_used_at DESC)'
      );
    },
  );
}
