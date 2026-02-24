import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/proxy/mobile_proxy_service.dart';
import 'package:intl/intl.dart';
import 'package:pbrowser/ui/shared/proxy_signal_widget.dart';

// ─────────────────────────────────────────────
//  PROFILE CARD
// ─────────────────────────────────────────────

class ProfileCard extends StatefulWidget {
  final BrowserProfile profile;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onClearSession;
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
    this.isSelectMode = false,
    this.isSelected = false,
    VoidCallback? onLongPress,
    VoidCallback? onSelect,
  })  : onLongPress = onLongPress ?? onRun,
        onSelect = onSelect ?? onRun;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isRotatingIp = false;

  Future<void> _rotateIp() async {
    final url = widget.profile.proxyConfig.rotationUrl;
    if (url == null || url.trim().isEmpty) return;
    if (_isRotatingIp) return;

    // ── Phase 1: Instant feedback ────────────────────────────────────
    // Show a persistent "in-progress" SnackBar immediately so the user
    // sees a reaction within one frame, rather than a frozen UI.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.tealAccent.shade200,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Requesting rotation for "${widget.profile.name}"…',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2A),
        behavior: SnackBarBehavior.floating,
        // Long duration — we'll manually dismiss it when the result arrives
        duration: const Duration(minutes: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    // ── Phase 2: Async call (non-blocking) ───────────────────────────
    // Card icon updates to spinner while waiting; rest of UI stays interactive.
    setState(() => _isRotatingIp = true);
    HapticFeedback.mediumImpact();
    final success = await MobileProxyService.rotateIp(url);

    if (!mounted) return;
    setState(() => _isRotatingIp = false);

    // Triple vibrate on failure — error tactile signal
    if (!success) {
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) HapticFeedback.vibrate();
    }

    if (!mounted) return;
    setState(() => _isRotatingIp = false);

    // ── Phase 3: Replace toast with result ───────────────────────────
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              size: 18,
              color: success ? Colors.tealAccent : Colors.redAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success
                    ? 'IP rotated for "${widget.profile.name}"'
                    : 'Rotation failed for "${widget.profile.name}"',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: success
            ? const Color(0xFF0D2B25)
            : const Color(0xFF2B0D0D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _CardBody(
        profile: widget.profile,
        isRotatingIp: _isRotatingIp,
        isSelectMode: widget.isSelectMode,
        isSelected: widget.isSelected,
        onRun: widget.onRun,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        onDuplicate: widget.onDuplicate,
        onClearSession: widget.onClearSession,
        onRotateIp: _rotateIp,
        onLongPress: widget.onLongPress,
        onSelect: widget.onSelect,
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
                            _OsBadge(platform: fp.platform),
                            const SizedBox(width: 10),
                            // Profile name
                  Expanded(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Rotate IP spinner / icon
                  if (hasRotation)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: isRotatingIp
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.tealAccent,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.swap_horiz_rounded,
                                  size: 18, color: Colors.tealAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Rotate IP',
                               onPressed: widget.onRotateIp,
                            ),
                    ),
                  // Context menu trigger
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

              const SizedBox(height: 10),

              // ── Visual chip row ───────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BrowserChip(userAgent: fp.userAgent),
                  _ProxyChip(proxy: proxy),
                  if (!fp.webrtcEnabled)
                    const _InfoChip(
                      label: 'WebRTC OFF',
                      icon: Icons.shield_outlined,
                      color: Colors.deepOrangeAccent,
                    ),
                  ...profile.tags.map((t) => _TagPill(tag: t)),
                ],
              ),

              const Spacer(),

              // ── Footer row ────────────────────────────
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: Colors.white24),
                  const SizedBox(width: 4),
                  Text(
                    _lastUsedText(profile.lastUsedAt),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  const Spacer(),
                  // Dynamic Proxy Ping Indicator
                  ProxySignalWidget(config: proxy),
                ],
              ),

              const SizedBox(height: 10),

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

  static String _lastUsedText(DateTime lastUsedAt) {
    final diff = DateTime.now().difference(lastUsedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(lastUsedAt);
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

class _OsBadge extends StatelessWidget {
  final String platform;
  const _OsBadge({required this.platform});

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
//  BROWSER CHIP
// ─────────────────────────────────────────────

class _BrowserChip extends StatelessWidget {
  final String userAgent;
  const _BrowserChip({required this.userAgent});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _parse(userAgent);
    return _InfoChip(label: label, icon: Icons.public_rounded, color: color);
  }

  static (String, Color) _parse(String ua) {
    // Edge check must come before Chrome
    if (ua.contains('Edg/')) {
      final m = RegExp(r'Edg/(\d+)').firstMatch(ua);
      return ('Edge ${m?.group(1) ?? ''}', Colors.blueAccent);
    }
    if (ua.contains('Firefox/')) {
      final m = RegExp(r'Firefox/(\d+)').firstMatch(ua);
      return ('Firefox ${m?.group(1) ?? ''}', Colors.orangeAccent);
    }
    if (ua.contains('Chrome/')) {
      final m = RegExp(r'Chrome/(\d+)').firstMatch(ua);
      return ('Chrome ${m?.group(1) ?? ''}', Colors.tealAccent);
    }
    if (ua.contains('Safari/') && !ua.contains('Chrome')) {
      return ('Safari', Colors.blueGrey);
    }
    return ('Browser', Colors.white54);
  }
}

// ─────────────────────────────────────────────
//  PROXY CHIP
// ─────────────────────────────────────────────

class _ProxyChip extends StatelessWidget {
  final ProxyConfig proxy;
  const _ProxyChip({required this.proxy});

  @override
  Widget build(BuildContext context) {
    switch (proxy.type) {
      case ProxyType.socks5:
        return const _InfoChip(
          label: 'SOCKS5',
          icon: Icons.security_rounded,
          color: Colors.purpleAccent,
        );
      case ProxyType.http:
        return const _InfoChip(
          label: 'HTTP',
          icon: Icons.http_rounded,
          color: Colors.orangeAccent,
        );
      case ProxyType.none:
        return const _InfoChip(
          label: 'Direct',
          icon: Icons.public_off_rounded,
          color: Colors.white38,
        );
    }
  }
}

// ─────────────────────────────────────────────
//  GENERIC INFO CHIP
// ─────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

// ─────────────────────────────────────────────
//  TAG PILL
// ─────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill({required this.tag});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.tealAccent,
      Colors.purpleAccent,
      Colors.amberAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];
    final color = colors[tag.hashCode.abs() % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.9),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
