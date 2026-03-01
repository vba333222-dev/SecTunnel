import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PrivacyCrashReporter {
  static Future<void> init() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      _reportError(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack);
      return true;
    };
    
    debugPrint('[Analytics] PrivacyCrashReporter initialized globally.');
  }

  static Future<void> _reportError(Object error, StackTrace? stackTrace) async {
    try {
      final rawLog = 'TIME: ${DateTime.now().toIso8601String()}\n'
          'ERROR: $error\n'
          'STACKTRACE:\n$stackTrace\n\n'
          '----------------------------------------\n\n';

      final sanitizedLog = _sanitizeLog(rawLog);
      
      // In production, you would upload this sanitized log
      // For this implementation, we save it locally for manual export.
      await _saveLogLocally(sanitizedLog);
    } catch (e) {
      // Failsafe: Do not crash the crash reporter
      debugPrint('[Analytics] FAILED to report error: $e');
    }
  }

  /// Scrub highly sensitive data from the stack race before it is written anywhere
  static String _sanitizeLog(String log) {
    String safeLog = log;

    // 1. Mask IPv4 Addresses
    final ipv4Regex = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');
    safeLog = safeLog.replaceAll(ipv4Regex, '[***REDACTED_IP***]');

    // 2. Mask IPv6 Addresses
    final ipv6Regex = RegExp(r'(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))');
    safeLog = safeLog.replaceAll(ipv6Regex, '[***REDACTED_IPV6***]');

    // 3. Mask URLs (HTTP/HTTPS/SOCKS) to prevent proxy credentials/hosts leaking
    final urlRegex = RegExp(r'(https?|socks5|socks4):\/\/[^\s]+');
    safeLog = safeLog.replaceAll(urlRegex, '[***REDACTED_URL***]');

    // 4. Mask UUIDs (Profile IDs)
    final uuidRegex = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', caseSensitive: false);
    safeLog = safeLog.replaceAll(uuidRegex, '[***REDACTED_PROFILE_ID***]');

    // 5. Mask User-Agent Strings (rudimentary masking)
    final uaRegex = RegExp(r'User-Agent:.*');
    safeLog = safeLog.replaceAll(uaRegex, 'User-Agent: [***REDACTED_AGENT***]');

    return safeLog;
  }

  static Future<void> _saveLogLocally(String logData) async {
    final dir = await getApplicationDocumentsDirectory();
    final crashDir = Directory('${dir.path}/crash_logs');
    
    if (!await crashDir.exists()) {
      await crashDir.create(recursive: true);
    }
    
    // Create a new log file or append to today's log
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    final logFile = File('${crashDir.path}/crash_$dateStr.txt');
    
    await logFile.writeAsString(logData, mode: FileMode.append);
    debugPrint('[Analytics] Saved anonymized crash log to ${logFile.path}');
  }
  
  static Future<String> exportLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final crashDir = Directory('${dir.path}/crash_logs');
    
    if (!await crashDir.exists()) {
      return "No crash logs found.";
    }
    
    final files = crashDir.listSync().whereType<File>().toList();
    if (files.isEmpty) {
      return "No crash logs found.";
    }
    
    // Sort by modification time, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    StringBuffer allLogs = StringBuffer();
    // Export up to 5 most recent files
    for (int i = 0; i < files.length && i < 5; i++) {
       allLogs.writeln("=== FILE: ${files[i].path.split('/').last} ===");
       final content = await files[i].readAsString();
       allLogs.writeln(content);
    }
    
    return allLogs.toString();
  }
  
  static Future<void> clearLogs() async {
     final dir = await getApplicationDocumentsDirectory();
     final crashDir = Directory('${dir.path}/crash_logs');
     if (await crashDir.exists()) {
       await crashDir.delete(recursive: true);
     }
  }
}
