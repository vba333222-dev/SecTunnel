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
import 'package:pbrowser/ui/shared/skeleton_card.dart';
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
  // ── Search ────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  String? _selectedTag;

  // ── Selection ─────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void dispose() {
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

    // Search query filter
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList(growable: false);
    }
    
    return filtered;
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
          final filtered = _applyFilter(allProfiles);
          final isLoading = !snapshot.hasData;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── AppBar (normal ↔ Contextual Action Bar) ─
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: const Color(0xFF141420),
                surfaceTintColor: Colors.transparent,
                expandedHeight: (_showSearch && !_isSelecting) ? 110 : 64,
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
                          totalCount: filtered.length,
                          allSelected:
                              _selectedIds.length == filtered.length,
                          hasRotatable: filtered.any((p) =>
                              _selectedIds.contains(p.id) &&
                              (p.proxyConfig.rotationUrl?.isNotEmpty ??
                                  false)),
                          onClose: _clearSelection,
                          onSelectAll: () => _selectedIds.length ==
                                  filtered.length
                              ? _clearSelection()
                              : _selectAll(filtered),
                          onDelete: () => _bulkDelete(allProfiles),
                          onRotateIp: () => _bulkRotateIp(allProfiles),
                          onLaunch: () => _bulkLaunch(allProfiles),
                        )
                      : _NormalBar(
                          key: const ValueKey('normal'),
                          profileCount:
                              isLoading ? null : allProfiles.length,
                          showSearch: _showSearch,
                          searchController: _searchController,
                          onSearchChanged: (v) =>
                              setState(() => _searchQuery = v),
                          onSearchClose: () => setState(() {
                            _showSearch = false;
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                          onSearchOpen: () =>
                              setState(() => _showSearch = true),
                          onExportLogs: () => _exportLogs(context),
                        ),
                ),
                // Hide default leading in selection mode
                leading: _isSelecting ? const SizedBox.shrink() : null,
                automaticallyImplyLeading: false,
              ),

              // ── Horizontal Tag Filter Bar ──────────────
              if (allProfiles.isNotEmpty && !_isSelecting)
                SliverToBoxAdapter(
                  child: _TagFilterBar(
                    profiles: allProfiles,
                    selectedTag: _selectedTag,
                    onTagSelected: (tag) => setState(() {
                      _selectedTag = tag;
                      _clearSelection();
                    }),
                  ),
                ),

              // ── Content ────────────────────────────────
              if (isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.crossAxisExtent < 600;
                      if (isNarrow) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, __) => const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                height: 190,
                                child: SkeletonCard(),
                              ),
                            ),
                            childCount: 6,
                          ),
                        );
                      } else {
                        return SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400, // Wider for tablets
                            mainAxisExtent: 190,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, __) => const SkeletonCard(),
                            childCount: 6,
                            addRepaintBoundaries: false,
                          ),
                        );
                      }
                    },
                  ),
                )
              else if (allProfiles.isEmpty)
                SliverFillRemaining(
                  child: _PremiumEmptyState(onCreateProfile: _createNewProfile),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No Results',
                    subtitle:
                        'No profiles match "${_searchController.text.trim()}"',
                    onAction: () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                    actionLabel: 'Clear Search',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.crossAxisExtent < 600;
                      
                      Widget buildCard(BrowserProfile profile) {
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

                      if (isNarrow) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            addRepaintBoundaries: true,
                            addAutomaticKeepAlives: false,
                            childCount: filtered.length,
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  height: 190,
                                  child: buildCard(filtered[index]),
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400, // Wider for tablets
                            mainAxisExtent: 190,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            addRepaintBoundaries: true,
                            addAutomaticKeepAlives: false,
                            childCount: filtered.length,
                            (context, index) => buildCard(filtered[index]),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  NORMAL APP BAR CONTENT
// ═════════════════════════════════════════════════════════════════════════════

class _NormalBar extends StatelessWidget {
  final int? profileCount;
  final bool showSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClose;
  final VoidCallback onSearchOpen;

  final VoidCallback onExportLogs;

  const _NormalBar({
    super.key,
    required this.profileCount,
    required this.showSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchClose,
    required this.onSearchOpen,
    required this.onExportLogs,
  });

  @override
  Widget build(BuildContext context) {
    if (showSearch) {
      return _SearchBar(
        controller: searchController,
        onChanged: onSearchChanged,
        onClose: onSearchClose,
      );
    }
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.tealAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'PBrowser',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
        const SizedBox(width: 8),
        if (profileCount != null)
          Text(
            '$profileCount profiles',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w400),
          ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.bug_report_outlined, color: Colors.white70),
          tooltip: 'Export Debug Logs',
          onPressed: onExportLogs,
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white70),
          tooltip: 'Search profiles',
          onPressed: onSearchOpen,
        ),
        const SizedBox(width: 4),
      ],
    );
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
//  SEARCH BAR
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.tealAccent,
        decoration: InputDecoration(
          hintText: 'Search profiles…',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Colors.tealAccent),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Colors.white54),
            onPressed: onClose,
          ),
        ),
      ),
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

// ─────────────────────────────────────────────
//  TAG FILTER BAR (Horizontal FilterChips)
// ─────────────────────────────────────────────

class _TagFilterBar extends StatelessWidget {
  final List<BrowserProfile> profiles;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;

  const _TagFilterBar({
    required this.profiles,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Extract unique sorted tags
    final tagsSet = <String>{};
    for (final p in profiles) {
      tagsSet.addAll(p.tags);
    }
    final allTags = tagsSet.toList()..sort();

    if (allTags.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: allTags.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip
            final isSelected = selectedTag == null;
            return FilterChip(
              label: const Text('All'),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => onTagSelected(null),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Colors.tealAccent.withValues(alpha: 0.15),
              side: BorderSide(
                color: isSelected ? Colors.tealAccent.shade400 : Colors.transparent,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.tealAccent.shade100 : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            );
          }

          final tag = allTags[index - 1];
          final isSelected = selectedTag == tag;

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

          return FilterChip(
            label: Text(tag),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onTagSelected(isSelected ? null : tag),
            backgroundColor: color.withValues(alpha: 0.08),
            selectedColor: color.withValues(alpha: 0.2),
            side: BorderSide(
              color: isSelected ? color.shade400 : color.withValues(alpha: 0.3),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : color.withValues(alpha: 0.9),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}
