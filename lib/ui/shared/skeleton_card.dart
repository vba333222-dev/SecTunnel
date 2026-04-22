import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SkeletonCard
//  Shimmer placeholder that exactly mirrors the ProfileCard layout.
//  Shown while the profile list is still loading from the database stream.
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  static const _base = Color(0xFF1C1C28);
  static const _highlight = Color(0xFF2E2E42);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────
            Row(
              children: [
                // OS badge placeholder
                _Bone(width: 34, height: 34, radius: 9),
                const SizedBox(width: 10),
                // Name placeholder
                _Bone(width: 110, height: 14, radius: 6),
                const Spacer(),
                // Menu icon placeholder
                _Bone(width: 20, height: 20, radius: 4),
              ],
            ),
            const SizedBox(height: 12),

            // ── Chip row ─────────────────────────────────
            Row(
              children: [
                _Bone(width: 68, height: 22, radius: 6),
                const SizedBox(width: 6),
                _Bone(width: 56, height: 22, radius: 6),
                const SizedBox(width: 6),
                _Bone(width: 72, height: 22, radius: 6),
              ],
            ),

            const Spacer(),

            // ── Footer row ────────────────────────────────
            Row(
              children: [
                _Bone(width: 80, height: 11, radius: 4),
                const Spacer(),
                _Bone(width: 8, height: 8, radius: 4, circle: true),
                const SizedBox(width: 4),
                _Bone(width: 36, height: 11, radius: 4),
              ],
            ),
            const SizedBox(height: 10),

            // ── Button placeholder ────────────────────────
            _Bone(width: double.infinity, height: 36, radius: 10),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Generic bone shape used inside the skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final bool circle;

  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Shimmer renders colour on top of this; any opaque colour works.
        color: Colors.white,
        borderRadius: circle
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(radius),
      ),
    );
  }
}
