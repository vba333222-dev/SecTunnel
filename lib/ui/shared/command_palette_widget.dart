import 'package:flutter/material.dart';
import 'package:SecTunnel/models/browser_profile.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

enum CommandType {
  rotateIp,
  openScripts,
  exportLogs,
  clearCookies, // Just examples, we will map them to actual callbacks
}

class CommandAction {
  final String sequence; // e.g. ">rotate"
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final CommandType type;

  const CommandAction({
    required this.sequence,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.type,
  });
}

const List<CommandAction> kGlobalCommands = [
  CommandAction(
    sequence: '>rotate',
    title: 'Force Rotate IP',
    subtitle: 'Rotate IP for all selected or available profiles',
    icon: Icons.swap_horiz_rounded,
    iconColor: Colors.tealAccent,
    type: CommandType.rotateIp,
  ),
  CommandAction(
    sequence: '>scripts',
    title: 'Manage User Scripts',
    subtitle: 'Open global User Scripts editor',
    icon: Icons.code_rounded,
    iconColor: Colors.orangeAccent,
    type: CommandType.openScripts,
  ),
  CommandAction(
    sequence: '>logs',
    title: 'Export Debug Logs',
    subtitle: 'Extract privacy-friendly crash logs',
    icon: Icons.bug_report_outlined,
    iconColor: Colors.redAccent,
    type: CommandType.exportLogs,
  ),
];

// ─────────────────────────────────────────────
// COMMAND PALETTE APP BAR
// ─────────────────────────────────────────────

class CommandPaletteBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final int? profileCount;
  
  const CommandPaletteBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
    this.profileCount,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFocus = focusNode.hasFocus;
    final bool hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      margin: EdgeInsets.symmetric(
          horizontal: hasFocus ? 0 : 16, 
          vertical: hasFocus ? 8 : 12),
      decoration: BoxDecoration(
        color: hasFocus 
            ? const Color(0xFF1E1E2A)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(hasFocus ? 0 : 14),
        border: Border.all(
          color: hasFocus 
              ? Colors.tealAccent.withOpacity(0.5) 
              : Colors.white.withOpacity(0.08),
          width: hasFocus ? 1.5 : 1,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            hasFocus ? Icons.keyboard_command_key : Icons.search_rounded,
            color: hasFocus ? Colors.tealAccent : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.w500),
              cursorColor: Colors.tealAccent,
              decoration: InputDecoration(
                hintText: hasFocus ? 'Type ">" for commands or search profiles' : 'Search or >command...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
              onPressed: onClear,
              splashRadius: 20,
            ),
          if (!hasText && !hasFocus && profileCount != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '$profileCount profiles',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COMMAND RESULTS OVERLAY/LIST
// ─────────────────────────────────────────────

class CommandPaletteOverlay extends StatelessWidget {
  final String query;
  final List<BrowserProfile> profileResults;
  final ValueChanged<CommandType> onCommandSelected;
  final ValueChanged<BrowserProfile> onProfileLaunch;

  const CommandPaletteOverlay({
    super.key,
    required this.query,
    required this.profileResults,
    required this.onCommandSelected,
    required this.onProfileLaunch,
  });

  @override
  Widget build(BuildContext context) {
    if (query.startsWith('>')) {
      final cmdQuery = query.toLowerCase();
      final matchedCommands = kGlobalCommands.where((cmd) {
        return cmd.sequence.toLowerCase().contains(cmdQuery) ||
               cmd.title.toLowerCase().contains(cmdQuery.replaceFirst('>', '').trim());
      }).toList();

      if (matchedCommands.isEmpty) {
        return _buildEmptyState(
          icon: Icons.electrical_services_rounded,
          title: 'Unknown Command',
          subtitle: 'Type >rotate, >scripts, or >logs',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: matchedCommands.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final cmd = matchedCommands[index];
          return _buildCommandTile(cmd);
        },
      );
    }

    // Otherwise, generic profile search results + quick hints
    if (query.isEmpty) {
      return _buildInitialHints();
    }

    if (profileResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Profiles Found',
        subtitle: 'Try a different search term or ">" for commands',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: profileResults.length + 1, // +1 for hint
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Press Enter to launch top result',
              style: TextStyle(fontSize: 12, color: Colors.tealAccent.withOpacity(0.6)),
            ),
          );
        }
        final profile = profileResults[index - 1];
        return _buildProfileShortcut(profile);
      },
    );
  }

  Widget _buildCommandTile(CommandAction cmd) {
    return InkWell(
      onTap: () => onCommandSelected(cmd.type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cmd.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(cmd.icon, color: cmd.iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cmd.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(cmd.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                cmd.sequence,
                style: TextStyle(fontFamily: 'monospace', color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileShortcut(BrowserProfile profile) {
    return InkWell(
      onTap: () => onProfileLaunch(profile),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.language_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const Icon(Icons.play_arrow_rounded, color: Colors.tealAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialHints() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Pro Tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.tealAccent.withOpacity(0.8), letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildHintRow(Icons.keyboard_return_rounded, 'Type profile name & press Enter to launch instantly'),
          const SizedBox(height: 12),
          _buildHintRow(Icons.keyboard_command_key, 'Type ">" to access advanced system commands'),
          const SizedBox(height: 32),
          Text('Available Commands', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 12),
          ...kGlobalCommands.map((cmd) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(cmd.sequence, style: const TextStyle(fontFamily: 'monospace', color: Colors.white70)),
                const SizedBox(width: 12),
                Text('—  ${cmd.title}', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHintRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
        ],
      ),
    );
  }
}
