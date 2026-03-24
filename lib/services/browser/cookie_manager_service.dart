import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

class CookieItem {
  final String domain;
  final String path;
  final String name;
  final String value;
  final bool secure;
  final bool httpOnly;
  final int? expirationDate;

  CookieItem({
    required this.domain,
    required this.path,
    required this.name,
    required this.value,
    this.secure = false,
    this.httpOnly = false,
    this.expirationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'path': path,
      'name': name,
      'value': value,
      'secure': secure,
      'httpOnly': httpOnly,
      if (expirationDate != null) 'expirationDate': expirationDate,
    };
  }

  factory CookieItem.fromJson(Map<String, dynamic> json) {
    return CookieItem(
      domain: json['domain'] ?? '',
      path: json['path'] ?? '/',
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      secure: json['secure'] ?? false,
      httpOnly: json['httpOnly'] ?? false,
      expirationDate: json['expirationDate'] is num ? (json['expirationDate'] as num).toInt() : null,
    );
  }
}

class CookieManagerService {
  /// Parse a JSON or Netscape string into a list of CookieItems
  static List<CookieItem> parseCookies(String content) {
    content = content.trim();
    if (content.isEmpty) return [];

    if (content.startsWith('[') || content.startsWith('{')) {
      return _parseJson(content);
    } else {
      return _parseNetscape(content);
    }
  }

  static List<CookieItem> _parseJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      final List<CookieItem> cookies = [];
      
      if (decoded is List) {
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            cookies.add(CookieItem.fromJson(item));
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        cookies.add(CookieItem.fromJson(decoded));
      }
      return cookies;
    } catch (e) {
      debugPrint('[CookieManager] JSON parsing error: $e');
      return [];
    }
  }

  static List<CookieItem> _parseNetscape(String netscapeStr) {
    final List<CookieItem> cookies = [];
    final lines = netscapeStr.split('\n');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      
      final parts = line.split(RegExp(r'\t+'));
      if (parts.length >= 7) {
        final domain = parts[0];
        // parts[1] is include subdomains flag
        final path = parts[2];
        final secure = parts[3].toUpperCase() == 'TRUE';
        final expirationDate = int.tryParse(parts[4]);
        final name = parts[5];
        final value = parts.sublist(6).join('\t'); 
        
        cookies.add(CookieItem(
          domain: domain,
          path: path,
          name: name,
          value: value,
          secure: secure,
          expirationDate: expirationDate == 0 ? null : expirationDate,
        ));
      }
    }
    
    return cookies;
  }

  /// Define session database path
  static String getSessionDbPath(String userDataFolder) {
    return path.join(userDataFolder, 'session.db');
  }

  /// Ensure session database exists and table is created
  static Database _initSessionDb(String userDataFolder) {
    final dbPath = getSessionDbPath(userDataFolder);
    final db = sqlite3.open(dbPath);
    // Create the cookies table if not exists
    db.execute('''
      CREATE TABLE IF NOT EXISTS cookies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        domain TEXT,
        path TEXT,
        name TEXT,
        value TEXT,
        secure INTEGER,
        http_only INTEGER,
        expiration_date INTEGER
      );
    ''');
    return db;
  }

  /// Save cookies to session SQLite DB
  static Future<void> saveSessionToDb(String userDataFolder, List<CookieItem> cookies) async {
    if (cookies.isEmpty) return;
    
    final db = _initSessionDb(userDataFolder);
    
    // Clear old cookies to avoid duplicates for the same name/domain/path
    db.execute('DELETE FROM cookies');
    
    final stmt = db.prepare('''
      INSERT INTO cookies (domain, path, name, value, secure, http_only, expiration_date)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''');
    
    db.execute('BEGIN TRANSACTION');
    try {
      for (final cookie in cookies) {
        stmt.execute([
          cookie.domain,
          cookie.path,
          cookie.name,
          cookie.value,
          cookie.secure ? 1 : 0,
          cookie.httpOnly ? 1 : 0,
          cookie.expirationDate,
        ]);
      }
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      debugPrint('[CookieManager] Error saving session to DB: $e');
    } finally {
      stmt.close();
      db.close();
    }
  }

  /// Load cookies from session SQLite DB
  static Future<List<CookieItem>> loadSessionFromDb(String userDataFolder) async {
    final dbPath = getSessionDbPath(userDataFolder);
    if (!File(dbPath).existsSync()) return [];

    final db = _initSessionDb(userDataFolder);
    final List<CookieItem> cookies = [];
    
    try {
      final results = db.select('SELECT * FROM cookies');
      for (final row in results) {
        cookies.add(CookieItem(
          domain: row['domain'] as String? ?? '',
          path: row['path'] as String? ?? '/',
          name: row['name'] as String? ?? '',
          value: row['value'] as String? ?? '',
          secure: (row['secure'] as int? ?? 0) == 1,
          httpOnly: (row['http_only'] as int? ?? 0) == 1,
          expirationDate: row['expiration_date'] as int?,
        ));
      }
    } catch (e) {
      debugPrint('[CookieManager] Error loading session from DB: $e');
    } finally {
      db.close();
    }
    
    return cookies;
  }

  /// Export active cookies for a specific Android WebView Profile ID
  static Future<List<CookieItem>> exportCookies(String profileId) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Export is only supported on Android');
    }

    try {
      // Find the app_webview_{profileId}/Default/Cookies database
      final supportDir = await getApplicationSupportDirectory();
      // On Android support directory is usually /data/user/0/com.app.package/files
      final appDataDir = supportDir.parent; // /data/user/0/com.app.package
      
      final dbFile = File('${appDataDir.path}/app_webview_$profileId/Default/Cookies');
      
      if (!await dbFile.exists()) {
        return [];
      }

      final db = sqlite3.open(dbFile.path, mode: OpenMode.readOnly);
      // Wait to prevent 'database is locked', handle gracefully but readOnly is usually fine
      final ResultSet results = db.select('SELECT host_key, path, is_secure, is_httponly, expires_utc, name, value FROM cookies');
      
      final List<CookieItem> cookies = [];
      for (final row in results) {
        int expiresUtc = row['expires_utc'] as int? ?? 0;
        int? unixExpiration;
        
        if (expiresUtc > 0) {
          // Chromium time format: microseconds since Jan 1, 1601
          // Unix time format: seconds since Jan 1, 1970
          // Difference is 11,644,473,600 seconds
          unixExpiration = (expiresUtc ~/ 1000000) - 11644473600;
        }

        cookies.add(CookieItem(
          domain: row['host_key'] as String? ?? '',
          path: row['path'] as String? ?? '/',
          name: row['name'] as String? ?? '',
          value: row['value'] as String? ?? '',
          secure: (row['is_secure'] as int? ?? 0) == 1,
          httpOnly: (row['is_httponly'] as int? ?? 0) == 1,
          expirationDate: unixExpiration,
        ));
      }
      db.close();
      
      return cookies;
    } catch (e) {
      debugPrint('[CookieManager] Export error: $e');
      rethrow;
    }
  }
}
