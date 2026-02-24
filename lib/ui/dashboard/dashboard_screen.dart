import 'package:flutter/material.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BrowserProfile> _applyFilter(List<BrowserProfile> profiles) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return profiles;
    return profiles
        .where((p) => p.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  // ── Navigation helpers ─────────────────────────────
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            const Text('Delete Profile?',
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${profile.name}"?\n'
          'This will also delete all associated browser data.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
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

    if (confirmed == true) {
      await widget.repository.deleteProfile(profile.id);
    }
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_profile_fab',
        onPressed: _createNewProfile,
        backgroundColor: Colors.tealAccent.shade700,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
              // ── SliverAppBar ─────────────────────────
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: const Color(0xFF141420),
                surfaceTintColor: Colors.transparent,
                expandedHeight: _showSearch ? 110 : 68,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  title: !_showSearch
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isLoading)
                              Text(
                                '${allProfiles.length} profiles',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        )
                      : null,
                  background: _showSearch
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _SearchBar(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              onClose: () => setState(() {
                                _showSearch = false;
                                _searchQuery = '';
                                _searchController.clear();
                              }),
                            ),
                          ),
                        )
                      : null,
                ),
                actions: [
                  if (!_showSearch)
                    IconButton(
                      icon: const Icon(Icons.search_rounded,
                          color: Colors.white70),
                      tooltip: 'Search profiles',
                      onPressed: () => setState(() => _showSearch = true),
                    ),
                  const SizedBox(width: 4),
                ],
              ),

              // ── Content ──────────────────────────────
              if (isLoading)
                // ━━ Shimmer skeleton grid while stream is loading ━━
                // Immediately shows 6 placeholder cards so the layout
                // feels populated — no blank-screen + spinner freeze.
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
                      // Shimmer handles its own painting internally;
                      // extra RepaintBoundary layers add unnecessary overhead.
                      addRepaintBoundaries: false,
                    ),
                  ),
                )
              else if (allProfiles.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.layers_outlined,
                    title: 'No Profiles Yet',
                    subtitle:
                        'Tap "New Profile" to create your first browser identity',
                    onAction: _createNewProfile,
                    actionLabel: 'Create Profile',
                  ),
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
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                        return ProfileCard(
                          key: ValueKey(profile.id),
                          profile: profile,
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

// ─────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────

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
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Colors.tealAccent),
          suffixIcon: IconButton(
            icon:
                const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
            onPressed: onClose,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────

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
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.38),
              ),
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
