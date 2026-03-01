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

  /// Define pending_cookies.json path
  static String getPendingCookiesPath(String userDataFolder) {
    return path.join(userDataFolder, 'pending_cookies.json');
  }

  /// Save raw cookie text to pending file
  static Future<void> savePendingCookies(String userDataFolder, String cookieText) async {
    final parsed = parseCookies(cookieText);
    if (parsed.isEmpty) return;

    final filePath = getPendingCookiesPath(userDataFolder);
    final file = File(filePath);
    
    final jsonList = parsed.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Export active cookies for a specific Android WebView Profile ID
  static Future<String> exportCookies(String profileId) async {
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
        throw Exception('Cookie database not found for profile $profileId');
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
      
      final jsonList = cookies.map((e) => e.toJson()).toList();
      return jsonEncode(jsonList);
    } catch (e) {
      debugPrint('[CookieManager] Export error: $e');
      rethrow;
    }
  }
}
