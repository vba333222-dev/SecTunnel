import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:pbrowser/services/proxy/mobile_proxy_service.dart';
import 'package:pbrowser/ui/profile/profile_form_screen.dart';
import 'package:pbrowser/ui/browser/browser_screen.dart';
import 'package:pbrowser/ui/dashboard/widgets/profile_card.dart';
import 'package:pbrowser/ui/shared/skeleton_card.dart';

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
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return profiles;
    return profiles
        .where((p) => p.name.toLowerCase().contains(q))
        .toList(growable: false);
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
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(repository: widget.repository),
      ),
    );
  }

  void _editProfile(BrowserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(
          repository: widget.repository,
          existingProfile: profile,
        ),
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
                        ),
                ),
                // Hide default leading in selection mode
                leading: _isSelecting ? const SizedBox.shrink() : null,
                automaticallyImplyLeading: false,
              ),

              // ── Content ────────────────────────────────
              if (isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 340,
                      mainAxisExtent: 190,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const SkeletonCard(),
                      childCount: 6,
                      addRepaintBoundaries: false,
                    ),
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
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 340,
                      mainAxisExtent: 190,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: false,
                      childCount: filtered.length,
                      (context, index) {
                        final profile = filtered[index];
                        final isSelected =
                            _selectedIds.contains(profile.id);
                        return ProfileCard(
                          key: ValueKey(profile.id),
                          profile: profile,
                          isSelectMode: _isSelecting,
                          isSelected: isSelected,
                          onLongPress: () => _enterSelectMode(profile.id),
                          onSelect: () => _toggleSelect(profile.id),
                          onRun: () => _launchBrowser(profile),
                          onEdit: () => _editProfile(profile),
                          onDelete: () => _deleteProfile(profile),
                        );
                      },
                    ),
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

  const _NormalBar({
    super.key,
    required this.profileCount,
    required this.showSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchClose,
    required this.onSearchOpen,
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

class _PremiumEmptyState extends StatefulWidget {
  final VoidCallback onCreateProfile;
  const _PremiumEmptyState({required this.onCreateProfile});

  @override
  State<_PremiumEmptyState> createState() => _PremiumEmptyStateState();
}

class _PremiumEmptyStateState extends State<_PremiumEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Pulsing Shield ────────────────────────────────
            _PulsingShield(animation: _pulse),

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
                    onTap: widget.onCreateProfile,
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

class _PulsingShield extends StatelessWidget {
  final Animation<double> animation;
  const _PulsingShield({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(animation.value);
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 120 + t * 16,
                height: 120 + t * 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        Colors.tealAccent.withValues(alpha: 0.10 + t * 0.08),
                    width: 1,
                  ),
                ),
              ),
              // Mid ring
              Container(
                width: 94 + t * 10,
                height: 94 + t * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        Colors.tealAccent.withValues(alpha: 0.18 + t * 0.12),
                    width: 1.5,
                  ),
                ),
              ),
              // Core circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.tealAccent.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.tealAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 36,
                  color: Colors.tealAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
