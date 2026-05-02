import 'package:flutter/foundation.dart';

// ─── Log Levels ─────────────────────────────────────────────────
enum LogLevel {
  info,
  warning,
  error;

  String get symbol {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

// ─── Log Tags ───────────────────────────────────────────────────
enum LogTag {
  rotate,
  network,
  validation,
  cooldown,
  system;

  String get label => name.toUpperCase();
}

// ─── Log Entry ──────────────────────────────────────────────────
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogTag tag;
  final String message;
  final String? profileId;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.profileId,
  });

  /// Formatted for console output:
  /// [12:30:01][INFO][ROTATE] Starting rotation
  String get formatted {
    final ts = '${_pad(timestamp.hour)}:${_pad(timestamp.minute)}:${_pad(timestamp.second)}';
    final prefix = profileId != null ? '[$profileId]' : '';
    return '[$ts][${level.symbol}][${tag.label}]$prefix $message';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Error Snapshot ─────────────────────────────────────────────
class ErrorSnapshot {
  final String profileId;
  final String error;
  final String state;
  final DateTime timestamp;

  const ErrorSnapshot({
    required this.profileId,
    required this.error,
    required this.state,
    required this.timestamp,
  });
}

// ─── Central Logger ─────────────────────────────────────────────
/// Lightweight in-memory logger with FIFO cap.
/// Singleton — accessible from any layer without DI overhead.
class AppLogger extends ChangeNotifier {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int _maxEntries = 50;

  final List<LogEntry> _entries = [];
  final Map<String, ErrorSnapshot> _lastErrors = {};

  bool debugMode = false;

  // ── Public API ──────────────────────────────────────────────

  List<LogEntry> get entries => List.unmodifiable(_entries);

  List<LogEntry> getFiltered({LogLevel? level, LogTag? tag}) {
    return _entries.where((e) {
      if (level != null && e.level != level) return false;
      if (tag != null && e.tag != tag) return false;
      return true;
    }).toList();
  }

  ErrorSnapshot? getLastError(String profileId) => _lastErrors[profileId];

  // ── Logging Methods ─────────────────────────────────────────

  void info(LogTag tag, String message, {String? profileId}) {
    _add(LogLevel.info, tag, message, profileId: profileId);
  }

  void warn(LogTag tag, String message, {String? profileId}) {
    _add(LogLevel.warning, tag, message, profileId: profileId);
  }

  void error(LogTag tag, String message, {String? profileId, String? state}) {
    _add(LogLevel.error, tag, message, profileId: profileId);

    // Store error snapshot
    if (profileId != null) {
      _lastErrors[profileId] = ErrorSnapshot(
        profileId: profileId,
        error: message,
        state: state ?? 'unknown',
        timestamp: DateTime.now(),
      );
    }
  }

  void clear() {
    _entries.clear();
    _lastErrors.clear();
    notifyListeners();
  }

  // ── Internal ────────────────────────────────────────────────

  void _add(LogLevel level, LogTag tag, String message, {String? profileId}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      profileId: profileId,
    );

    _entries.add(entry);

    // FIFO cap
    while (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }

    // Always print to console
    debugPrint(entry.formatted);

    // Notify UI listeners (debug panel)
    notifyListeners();
  }
}
