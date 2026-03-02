import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/services/analytics/privacy_crash_reporter.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:pbrowser/services/proxy/mobile_proxy_service.dart';
import 'package:pbrowser/ui/profile/profile_form_screen.dart';
import 'package:pbrowser/ui/browser/browser_screen.dart';
import 'package:pbrowser/ui/dashboard/widgets/profile_card.dart';
import 'package:pbrowser/ui/shared/command_palette_widget.dart';
import 'package:pbrowser/ui/profile/user_scripts_screen.dart';
import 'package:pbrowser/services/browser/userscript_service.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';
import 'package:pbrowser/ui/shared/themed_lottie.dart';

class DashboardScreen extends StatefulWidget {
  final ProfileRepository repository;

  const DashboardScreen({
    super.key,
    required this.repository,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Search & Command Palette ────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedTag;

  // ── Selection ─────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {}); // Re-render when focus changes for overlay
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────
  List<BrowserProfile> _applyFilter(List<BrowserProfile> profiles) {
    var filtered = profiles;
    
    // Tag filter
    if (_selectedTag != null) {
      filtered = filtered.where((p) => p.tags.contains(_selectedTag)).toList(growable: false);
    }

    // Search query filter (applies across all tabs)
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList(growable: false);
    }
    
    return filtered;
  }

  // Helper to extract unique tabs from all profiles
  List<String> _extractTabs(List<BrowserProfile> profiles) {
    final tags = <String>{};
    for (var p in profiles) {
      tags.addAll(p.tags);
    }
    final sortedTags = tags.toList()..sort();
    return ['All', ...sortedTags];
  }

  // ── Selection helpers ─────────────────────────────────
  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<BrowserProfile> profiles) {
    setState(() => _selectedIds.addAll(profiles.map((p) => p.id)));
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _enterSelectMode(String firstId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedIds.clear();
      _selectedIds.add(firstId);
    });
  }

  // ── Navigation helpers ─────────────────────────────────
  void _createNewProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileFormScreen(repository: widget.repository);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.scaled,
            fillColor: const Color(0xFF0A0A0A),
            child: child,
          );
        },
      ),
    );
  }

  void _editProfile(BrowserProfile profile) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileFormScreen(
            repository: widget.repository,
            existingProfile: profile,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.scaled,
            fillColor: const Color(0xFF0A0A0A),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _launchBrowser(BrowserProfile profile) async {
    await widget.repository.markAsUsed(profile.id);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BrowserScreen(profile: profile),
        ),
      );
    }
  }

  Future<void> _deleteProfile(BrowserProfile profile) async {
    final confirmed = await _showDeleteDialog(
      count: 1,
      names: [profile.name],
    );
    if (confirmed == true) {
      await widget.repository.deleteProfile(profile.id);
    }
  }

  Future<void> _duplicateProfile(BrowserProfile profile) async {
    HapticFeedback.mediumImpact();
    await widget.repository.duplicateProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile duplicated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearSession(BrowserProfile profile) async {
    HapticFeedback.lightImpact();
    await widget.repository.clearProfileSession(profile.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session cleared for "${profile.name}".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Bulk actions ──────────────────────────────────────

  /// Bulk delete with a single confirm dialog.
  Future<void> _bulkDelete(List<BrowserProfile> allProfiles) async {
    final targets = allProfiles
        .where((p) => _selectedIds.contains(p.id))
        .toList(growable: false);
    if (targets.isEmpty) return;

    final confirmed = await _showDeleteDialog(
      count: targets.length,
      names: targets.map((p) => p.name).toList(),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    _clearSelection();
    for (final p in targets) {
      await widget.repository.deleteProfile(p.id);
    }
  }

  /// Bulk rotate IP — 3-phase toast per profile card (fire-and-forget).
  Future<void> _bulkRotateIp(List<BrowserProfile> allProfiles) async {
    final targets = allProfiles
        .where((p) =>
            _selectedIds.contains(p.id) &&
            (p.proxyConfig.rotationUrl?.isNotEmpty ?? false))
        .toList(growable: false);

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('None of the selected profiles have a rotation URL.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _clearSelection();

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
                  strokeWidth: 2, color: Colors.tealAccent.shade200),
            ),
            const SizedBox(width: 14),
            Text('Rotating IP for ${targets.length} profile(s)…',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(minutes: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    int successCount = 0;
    for (final p in targets) {
      final ok = await MobileProxyService.rotateIp(p.proxyConfig.rotationUrl!);
      if (ok) successCount++;
    }

    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              successCount == targets.length
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              size: 18,
              color: successCount == targets.length
                  ? Colors.tealAccent
                  : Colors.orangeAccent,
            ),
            const SizedBox(width: 10),
            Text(
              '$successCount / ${targets.length} rotations succeeded',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: successCount == targets.length
            ? const Color(0xFF0D2B25)
            : const Color(0xFF2B200D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /// Bulk launch — opens browser screens sequentially with brief gaps.
  Future<void> _bulkLaunch(List<BrowserProfile> allProfiles) async {
    final targets = allProfiles
        .where((p) => _selectedIds.contains(p.id))
        .toList(growable: false);
    if (targets.isEmpty) return;
    HapticFeedback.lightImpact();
    _clearSelection();

    // Capture navigator before any async gap to satisfy
    // use_build_context_synchronously lint.
    final nav = Navigator.of(context);

    for (final p in targets) {
      if (!mounted) return;
      await widget.repository.markAsUsed(p.id);
      nav.push(MaterialPageRoute(builder: (_) => BrowserScreen(profile: p)));
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  // ── Delete dialog helper ─────────────────────────────
  Future<bool?> _showDeleteDialog({
    required int count,
    required List<String> names,
  }) {
    final label = count == 1 ? '"${names.first}"' : '$count profiles';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text('Delete $label?',
                style:
                    const TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: Text(
          'This will permanently delete $label and all associated browser data.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs(BuildContext context) async {
    try {
      final logs = await PrivacyCrashReporter.exportLogs();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2A),
            title: const Text('Anonymous Crash Logs', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: SelectableText(
                logs,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: logs));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logs copied to clipboard (Scrubbed)')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy All'),
              ),
              TextButton(
                onPressed: () async {
                  await PrivacyCrashReporter.clearLogs();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logs cleared')),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to read logs: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: AnimatedScale(
        scale: _isSelecting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: FloatingActionButton.extended(
          heroTag: 'create_profile_fab',
          onPressed: _createNewProfile,
          backgroundColor: Colors.tealAccent.shade700,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Profile',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      body: StreamBuilder<List<BrowserProfile>>(
        stream: widget.repository.watchAllProfiles(),
        builder: (context, snapshot) {
          final allProfiles = snapshot.data ?? [];
          final isLoading = !snapshot.hasData;

          // Build our dynamic tabs based on all available profiles
          final tabs = _extractTabs(allProfiles);

          // If no data, show loading state immediately
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          return DefaultTabController(
            length: tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // ── AppBar (normal ↔ Contextual Action Bar) ─
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    backgroundColor: const Color(0xFF141420),
                    surfaceTintColor: Colors.transparent,
                    expandedHeight: 70,
                    // AnimatedSwitcher slides between Normal ↔ CAB
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _isSelecting
                          ? _ContextualActionBar(
                              key: const ValueKey('cab'),
                              selectedCount: _selectedIds.length,
                              totalCount: allProfiles.length, // total changes based on tab context usually, but global is fine here
                              allSelected:
                                  _selectedIds.length == allProfiles.length,
                              hasRotatable: allProfiles.any((p) =>
                                  _selectedIds.contains(p.id) &&
                                  (p.proxyConfig.rotationUrl?.isNotEmpty ??
                                      false)),
                              onClose: _clearSelection,
                              onSelectAll: () => _selectedIds.length ==
                                      allProfiles.length
                                  ? _clearSelection()
                                  : _selectAll(allProfiles),
                              onDelete: () => _bulkDelete(allProfiles),
                              onRotateIp: () => _bulkRotateIp(allProfiles),
                              onLaunch: () => _bulkLaunch(allProfiles),
                            )
                          : CommandPaletteBar(
                              key: const ValueKey('normal'),
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onClear: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _searchFocusNode.unfocus();
                              },
                              onChanged: (v) => setState(() => _searchQuery = v),
                              onSubmitted: (v) => _handleCommandSubmitted(v, _applyFilter(allProfiles), allProfiles),
                              profileCount: isLoading ? null : allProfiles.length,
                            ),
                    ),
                    // Hide default leading in selection mode
                    leading: _isSelecting ? const SizedBox.shrink() : null,
                    automaticallyImplyLeading: false,
                  ),

                  // ── Tab Bar ──────────────────────────────
                  if (!_isSelecting && (!(_searchFocusNode.hasFocus || _searchQuery.isNotEmpty)))
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          indicatorColor: Colors.tealAccent,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelColor: Colors.tealAccent,
                          unselectedLabelColor: Colors.white54,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          // Optional padding around the entire TabBar
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                          onTap: (index) {
                            // Clear selection when changing tabs to prevent mass-actions on invisible profiles
                            if (_isSelecting) _clearSelection();
                          },
                        ),
                      ),
                    ),
                ];
              },
              
              // ── Body / Tab Views ──────────────────────────────
              body: (_searchFocusNode.hasFocus || _searchQuery.isNotEmpty) && !_isSelecting
                ? CommandPaletteOverlay(
                    query: _searchQuery,
                    profileResults: _applyFilter(allProfiles),
                    onCommandSelected: (type) => _handleCommandAction(type, allProfiles),
                    onProfileLaunch: (profile) {
                      _searchFocusNode.unfocus();
                      _launchBrowser(profile);
                    },
                  )
                : allProfiles.isEmpty
                  ? _PremiumEmptyState(onCreateProfile: _createNewProfile)
                  : TabBarView(
                      children: tabs.map((tab) {
                        // Filter profiles for this specific tab
                        List<BrowserProfile> tabProfiles = allProfiles;
                        if (tab != 'All') {
                          tabProfiles = tabProfiles.where((p) => p.tags.contains(tab)).toList(growable: false);
                        }
                        
                        // Apply active search query filter over the top of the tab filter
                        final filteredForTab = _applyFilter(tabProfiles);

                        if (filteredForTab.isEmpty) {
                           return _EmptyState(
                             icon: Icons.folder_open_rounded,
                             title: 'Empty Workspace',
                             subtitle: tab == 'All' ? 'No profiles found.' : 'No profiles found in "$tab".',
                             onAction: _createNewProfile,
                             actionLabel: 'Create Profile',
                           );
                        }

                        // Use a dedicated ScrollView for each tab
                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              sliver: SliverLayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.crossAxisExtent < 600;
                                  if (isNarrow) {
                                    return SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final profile = filteredForTab[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: SizedBox(
                                              height: 190,
                                              child: _buildCard(profile),
                                            ),
                                          );
                                        },
                                        childCount: filteredForTab.length,
                                      ),
                                    );
                                  } else {
                                    return SliverGrid(
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 400,
                                        mainAxisExtent: 190,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) =>
                                            _buildCard(filteredForTab[index]),
                                        childCount: filteredForTab.length,
                                        addRepaintBoundaries: false,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          );
        },
      ),
    );
  }

  // ── Profile Card Builder ──────────────────────────────
  Widget _buildCard(BrowserProfile profile) {
    final isSelected = _selectedIds.contains(profile.id);
    final rotator = context.watch<ModemRotatorService>();
    final isThisRotating = rotator.isRotating && rotator.targetProfileId == profile.id;
    
    return ProfileCard(
      key: ValueKey(profile.id),
      profile: profile,
      isSelectMode: _isSelecting,
      isSelected: isSelected,
      isRotatingIp: isThisRotating,
      onLongPress: () => _enterSelectMode(profile.id),
      onSelect: () => _toggleSelect(profile.id),
      onRun: () => _launchBrowser(profile),
      onEdit: () => _editProfile(profile),
      onDelete: () => _deleteProfile(profile),
      onDuplicate: () => _duplicateProfile(profile),
      onClearSession: () => _clearSession(profile),
      onRotateIp: () {
        if (profile.proxyConfig.rotationUrl?.isNotEmpty == true) {
          context.read<ModemRotatorService>().rotateIp(
            profile.proxyConfig.rotationUrl!,
            profile.id,
            profile.name,
          );
        }
      },
    );
  }

  // ── Command Handlers ────────────────────────────────
  void _handleCommandAction(CommandType type, List<BrowserProfile> allProfiles) {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() => _searchQuery = '');

    switch (type) {
      case CommandType.rotateIp:
        final rotatable = allProfiles.where((p) => (p.proxyConfig.rotationUrl ?? '').isNotEmpty).toList();
        if (rotatable.isNotEmpty) {
          _bulkRotateIp(rotatable);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No profiles with rotatable IPs')));
        }
        break;
      case CommandType.exportLogs:
        _exportLogs(context);
        break;
      case CommandType.openScripts:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => UserScriptsScreen(
            service: context.read<UserScriptService>(),
            profileId: 'global',
          ),
        ));
        break;
      case CommandType.clearCookies:
        break;
    }
  }

  void _handleCommandSubmitted(String value, List<BrowserProfile> filtered, List<BrowserProfile> allProfiles) {
    final query = value.trim();
    if (query.isEmpty) {
      _searchFocusNode.unfocus();
      return;
    }

    if (query.startsWith('>')) {
      final cmdQuery = query.toLowerCase();
      final matched = kGlobalCommands.where((cmd) => 
         cmd.sequence.toLowerCase().contains(cmdQuery) ||
         cmd.title.toLowerCase().contains(cmdQuery.replaceFirst('>', '').trim())
      ).toList();
      
      if (matched.isNotEmpty) {
        _handleCommandAction(matched.first.type, allProfiles);
      }
    } else {
      if (filtered.isNotEmpty) {
        _searchFocusNode.unfocus();
        _launchBrowser(filtered.first);
      }
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF141420), // Match the AppBar background color perfectly
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CONTEXTUAL ACTION BAR
// ═════════════════════════════════════════════════════════════════════════════

class _ContextualActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final bool allSelected;
  final bool hasRotatable;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onRotateIp;
  final VoidCallback onLaunch;

  const _ContextualActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.allSelected,
    required this.hasRotatable,
    required this.onClose,
    required this.onSelectAll,
    required this.onDelete,
    required this.onRotateIp,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Close selection
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel selection',
          onPressed: onClose,
          color: Colors.white,
        ),
        // Count badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$selectedCount selected',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const Spacer(),
        // Select all / deselect all
        Tooltip(
          message: allSelected ? 'Deselect all' : 'Select all',
          child: IconButton(
            icon: Icon(
              allSelected
                  ? Icons.deselect_rounded
                  : Icons.select_all_rounded,
              color: Colors.white70,
            ),
            onPressed: onSelectAll,
          ),
        ),
        // Rotate IP (only if any selected has rotation URL)
        if (hasRotatable)
          Tooltip(
            message: 'Rotate IP (selected)',
            child: IconButton(
              icon: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.tealAccent),
              onPressed: onRotateIp,
            ),
          ),
        // Launch
        Tooltip(
          message: 'Launch selected',
          child: IconButton(
            icon: const Icon(Icons.play_arrow_rounded,
                color: Colors.tealAccent),
            onPressed: onLaunch,
          ),
        ),
        // Delete
        Tooltip(
          message: 'Delete selected',
          child: IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════

// ── Plain empty state (used for no-search-results) ───────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAction;
  final String actionLabel;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: Colors.white24),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.38)),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PREMIUM EMPTY STATE  (shown when there are no profiles at all)
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumEmptyState extends StatelessWidget {
  final VoidCallback onCreateProfile;
  const _PremiumEmptyState({required this.onCreateProfile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Lottie Shield ────────────────────────────────
            const ThemedLottie(
              animation: LottieAnimation.emptyProfiles,
              width: 180,
              height: 180,
            ),

            const SizedBox(height: 32),

            // ── Headline ─────────────────────────────────────
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.tealAccent, Color(0xFF00E5CC), Colors.cyanAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'Your Identities Await',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white, // masked by shader
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Create isolated browser profiles with unique\nfingerprints, proxies, and identities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),

            const SizedBox(height: 28),

            // ── Feature tiles ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FeatureTile(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Anonymous',
                  color: Colors.tealAccent,
                ),
                const SizedBox(width: 12),
                _FeatureTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Isolated',
                  color: Colors.purpleAccent,
                ),
                const SizedBox(width: 12),
                _FeatureTile(
                  icon: Icons.public_rounded,
                  label: 'Geo-Aware',
                  color: Colors.blueAccent,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Hero CTA button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.shade700,
                      const Color(0xFF00BFA5),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.tealAccent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onCreateProfile,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.white12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_rounded,
                              color: Colors.black, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Create Your First Profile',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.black87, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing animated shield illustration ─────────────────────────────────────



// ── Feature tile ─────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureTile(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
