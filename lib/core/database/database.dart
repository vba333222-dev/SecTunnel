import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class AppDatabase {
  static Database? _database;
  static final AppDatabase instance = AppDatabase._internal();
  
  AppDatabase._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dbFolder.path, 'pbrowser.db');
    
    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE browser_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        proxy_type TEXT NOT NULL,
        proxy_host TEXT,
        proxy_port INTEGER,
        proxy_username TEXT,
        proxy_password TEXT,
        proxy_rotation_url TEXT,
        fingerprint_json TEXT NOT NULL,
        user_data_folder TEXT NOT NULL,
        keep_alive_enabled INTEGER DEFAULT 0,
        clear_browsing_data INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER NOT NULL,
        tags_json TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE user_scripts (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        url_pattern TEXT NOT NULL,
        js_payload TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        run_at TEXT DEFAULT 'document_idle',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    await db.execute(
      'CREATE INDEX idx_profiles_last_used ON browser_profiles(last_used_at DESC)'
    );
    await db.execute(
      'CREATE INDEX idx_userscripts_profile ON user_scripts(profile_id)'
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_scripts (
          id TEXT PRIMARY KEY,
          profile_id TEXT NOT NULL,
          name TEXT NOT NULL,
          url_pattern TEXT NOT NULL,
          js_payload TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          run_at TEXT DEFAULT 'document_idle',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_userscripts_profile ON user_scripts(profile_id)'
      );
      await db.execute(
        'ALTER TABLE browser_profiles ADD COLUMN proxy_rotation_url TEXT'
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE browser_profiles ADD COLUMN keep_alive_enabled INTEGER DEFAULT 0'
      );
      await db.execute(
        'ALTER TABLE browser_profiles ADD COLUMN tags_json TEXT'
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE browser_profiles ADD COLUMN clear_browsing_data INTEGER DEFAULT 0'
      );
    }
  }
}