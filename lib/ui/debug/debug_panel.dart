import 'package:flutter/material.dart';
import 'package:sec_tunnel/core/logging/logger.dart';

/// Hidden debug panel showing structured logs with level filtering.
/// Access: long-press version text, or programmatic toggle via [AppLogger.debugMode].
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  LogLevel? _filterLevel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLogger.instance,
      builder: (context, _) {
        final logger = AppLogger.instance;
        final logs = _filterLevel != null
            ? logger.getFiltered(level: _filterLevel)
            : logger.entries;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Debug Logs',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Filter chips
              _FilterChip(
                label: 'ALL',
                isActive: _filterLevel == null,
                color: Colors.white,
                onTap: () => setState(() => _filterLevel = null),
              ),
              _FilterChip(
                label: 'ERR',
                isActive: _filterLevel == LogLevel.error,
                color: Colors.red,
                onTap: () => setState(() => _filterLevel = LogLevel.error),
              ),
              _FilterChip(
                label: 'WARN',
                isActive: _filterLevel == LogLevel.warning,
                color: Colors.orange,
                onTap: () => setState(() => _filterLevel = LogLevel.warning),
              ),
              _FilterChip(
                label: 'INFO',
                isActive: _filterLevel == LogLevel.info,
                color: Colors.cyan,
                onTap: () => setState(() => _filterLevel = LogLevel.info),
              ),
              const SizedBox(width: 8),
              // Clear logs
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Clear logs',
                onPressed: () => logger.clear(),
              ),
            ],
          ),
          body: logs.isEmpty
              ? const Center(
                  child: Text(
                    'No logs yet.\nTrigger a rotation to see entries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    // Show newest first
                    final entry = logs[logs.length - 1 - index];
                    return _LogTile(entry: entry);
                  },
                ),
        );
      },
    );
  }
}

// ─── Individual Log Row ─────────────────────────────────────────
class _LogTile extends StatelessWidget {
  final LogEntry entry;

  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(entry.level);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            '${_pad(entry.timestamp.hour)}:${_pad(entry.timestamp.minute)}:${_pad(entry.timestamp.second)}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.white30,
            ),
          ),
          const SizedBox(width: 6),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              entry.level.symbol,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Tag
          Text(
            '[${entry.tag.label}]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          // Message
          Expanded(
            child: Text(
              entry.message,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.cyan;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Filter Chip ────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? color : Colors.white24,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}
