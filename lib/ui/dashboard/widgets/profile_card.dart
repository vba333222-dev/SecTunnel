import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/browser/cookie_manager_service.dart';
import 'dart:convert';
import 'package:pbrowser/services/background/headless_keep_alive_service.dart';
import 'package:intl/intl.dart';
import 'package:pbrowser/ui/shared/proxy_signal_widget.dart';

// ─────────────────────────────────────────────
//  PROFILE CARD
// ─────────────────────────────────────────────

class ProfileCard extends StatelessWidget {
  final BrowserProfile profile;
  final bool isRotatingIp;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onClearSession;
  final VoidCallback onRotateIp;
  // ── Selection ──────────────────────────────
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onSelect;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onClearSession,
    required this.onRotateIp,
    this.isRotatingIp = false,
    this.isSelectMode = false,
    this.isSelected = false,
    VoidCallback? onLongPress,
    VoidCallback? onSelect,
  })  : onLongPress = onLongPress ?? onRun,
        onSelect = onSelect ?? onRun;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _CardBody(
        profile: profile,
        isRotatingIp: isRotatingIp,
        isSelectMode: isSelectMode,
        isSelected: isSelected,
        onRun: onRun,
        onEdit: onEdit,
        onDelete: onDelete,
        onDuplicate: onDuplicate,
        onClearSession: onClearSession,
        onRotateIp: onRotateIp,
        onLongPress: onLongPress,
        onSelect: onSelect,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARD BODY  (Stateful for press-scale animation)
// ─────────────────────────────────────────────

class _CardBody extends StatefulWidget {
  final BrowserProfile profile;
  final bool isRotatingIp;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onClearSession;
  final VoidCallback onRotateIp;
  final VoidCallback onLongPress;
  final VoidCallback onSelect;

  const _CardBody({
    required this.profile,
    required this.isRotatingIp,
    required this.isSelectMode,
    required this.isSelected,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onClearSession,
    required this.onRotateIp,
    required this.onLongPress,
    required this.onSelect,
  });

  @override
  State<_CardBody> createState() => _CardBodyState();
}

class _CardBodyState extends State<_CardBody> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.isSelectMode) {
      HapticFeedback.lightImpact();
      widget.onSelect();
    } else {
      HapticFeedback.mediumImpact();
      widget.onRun();
    }
  }

  void _handleLongPress() {
    if (widget.isSelectMode) return;
    HapticFeedback.mediumImpact();
    _showContextMenu(context);
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final profile = widget.profile;
        final hasRotation = profile.proxyConfig.rotationUrl?.isNotEmpty ?? false;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.play_arrow_rounded, color: Colors.tealAccent),
                  title: const Text('Launch Browser', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRun();
                  },
                ),
                if (hasRotation)
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded, color: Colors.blueAccent),
                    title: const Text('Force Rotate IP', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onRotateIp();
                    },
                  ),
                if (profile.keepAliveEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.play_circle_fill, color: Colors.green),
                    title: const Text('Start Farm (Bg)', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await HeadlessKeepAliveService.startHeadlessSession(profile.id, profile.name);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Started Background Farm' : 'Failed to start')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.stop_circle, color: Colors.orange),
                    title: const Text('Stop Farm', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      await HeadlessKeepAliveService.stopHeadlessSession();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stopped Background Farm')),
                        );
                      }
                    },
                  ),
                  const Divider(color: Colors.white12, height: 16),
                ],
                ListTile(
                  leading: const Icon(Icons.cookie, color: Colors.blue),
                  title: const Text('Export Session', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleExportSession(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                  title: const Text('Duplicate Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDuplicate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cookie_outlined, color: Colors.orangeAccent),
                  title: const Text('Clear Cookies / Session', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onClearSession();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                  title: const Text('Edit Configuration', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_box_outlined, color: Colors.white70),
                  title: const Text('Select Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onLongPress(); // triggers selection mode
                  },
                ),
                const Divider(color: Colors.white12, height: 16),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Delete Profile', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final fp = profile.fingerprintConfig;
    final proxy = profile.proxyConfig;
    final isRotatingIp = widget.isRotatingIp;
    final isSelectMode = widget.isSelectMode;
    final isSelected = widget.isSelected;
    final hasRotation =
        proxy.rotationUrl != null && proxy.rotationUrl!.isNotEmpty;

    // Selected card border animated
    final borderColor = isSelected
        ? Colors.tealAccent.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.08);
    final borderWidth = isSelected ? 1.8 : 1.0;
    final cardGlow = isSelected
        ? [BoxShadow(color: Colors.tealAccent.withValues(alpha: 0.18), blurRadius: 12, spreadRadius: 1)]
        : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: isSelectMode ? null : _handleLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Main card ─────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: cardGlow,
              ),
              child: Card(
                elevation: 0,
                color: isSelected
                    ? const Color(0xFF111A1A)
                    : const Color(0xFF16161F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: borderWidth),
                ),
                child: InkWell(
                  onTap: null, // Tap handled by outer GestureDetector
                  onLongPress: null,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.tealAccent.withValues(alpha: 0.08),
                  highlightColor: Colors.tealAccent.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row ────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // OS badge
                            Hero(
                              tag: 'os_badge_${profile.id}',
                              child: OsBadge(platform: fp.platform),
                            ),
                            const SizedBox(width: 12),
                            // Profile name
                            Expanded(
                              child: Hero(
                                tag: 'profile_name_${profile.id}',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            if (profile.keepAliveEnabled)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Tooltip(
                                  message: 'Keep-Alive Enabled',
                                  child: Icon(Icons.flash_on, color: Colors.yellow, size: 16),
                                ),
                              ),
                            if (hasRotation) ...[
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Rotate IP',
                                onPressed: widget.onRotateIp,
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Context menu
                            IconButton(
                              icon: Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showContextMenu(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Proxy Health Indicator
                        ProxySignalWidget(config: proxy),
                        
                        const Spacer(),

                        // ── Launch button ─────────────────
                        _LaunchButton(
                          onTap: isSelectMode ? widget.onSelect : widget.onRun,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Checkbox overlay ─────────────────────
            // AnimatedScale: 0 → 1 when entering selection mode
            Positioned(
              top: 8,
              left: 8,
              child: AnimatedScale(
                scale: isSelectMode ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: _CheckboxBadge(checked: isSelected),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _handleExportSession(BuildContext context) async {
    try {
      final cookiesArray = await CookieManagerService.exportCookies(widget.profile.id);
      final jsonCookies = jsonEncode(cookiesArray.map((c) => c.toJson()).toList());
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('Exported Cookies', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonCookies,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: jsonCookies));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cookies copied to clipboard')),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Copy to Clipboard', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export cookies: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
//  CHECKBOX BADGE  (animated fill circle)
// ─────────────────────────────────────────────

class _CheckboxBadge extends StatelessWidget {
  final bool checked;
  const _CheckboxBadge({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? Colors.tealAccent : Colors.black.withValues(alpha: 0.55),
        border: Border.all(
          color: checked
              ? Colors.tealAccent
              : Colors.white.withValues(alpha: 0.5),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
          : null,
    );
  }
}

// ─────────────────────────────────────────────
//  OS BADGE
// ─────────────────────────────────────────────

class OsBadge extends StatelessWidget {
  final String platform;
  const OsBadge({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _resolve(platform);
    return Tooltip(
      message: label,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  static (IconData, Color, String) _resolve(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('win')) {
      return (Icons.window_rounded, Colors.blueAccent, 'Windows');
    }
    if (p.contains('mac') || p.contains('intel')) {
      return (Icons.apple, const Color(0xFFB0B0B0), 'macOS');
    }
    if (p.contains('iphone') || p.contains('ipad')) {
      return (Icons.phone_iphone, Colors.blueGrey, 'iOS');
    }
    if (p.contains('android') || p.contains('arm')) {
      return (Icons.android, Colors.greenAccent, 'Android');
    }
    // Linux
    return (Icons.terminal, Colors.amberAccent, 'Linux');
  }
}


// ─────────────────────────────────────────────
//  LAUNCH BUTTON
// ─────────────────────────────────────────────

class _LaunchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LaunchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.tealAccent.shade700,
              Colors.teal.shade400,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.tealAccent.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.white12,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 18, color: Colors.black),
                SizedBox(width: 6),
                Text(
                  'Launch',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
