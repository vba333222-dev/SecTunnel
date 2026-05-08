import 'package:flutter/material.dart';

class IdentityReviewStep extends StatelessWidget {
  const IdentityReviewStep({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Identity',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your identity has been assembled and validated for high realism.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildReviewItem(
                  icon: Icons.verified_user_rounded,
                  color: Colors.blue,
                  title: 'Ecological Fit',
                  value: 'Perfect match for Indonesian mobile clusters.',
                ),
                const Divider(height: 32),
                _buildReviewItem(
                  icon: Icons.memory_rounded,
                  color: Colors.purple,
                  title: 'Hardware Integrity',
                  value: 'GPU and SoC signatures are coherent with OS version.',
                ),
                const Divider(height: 32),
                _buildReviewItem(
                  icon: Icons.public_rounded,
                  color: Colors.green,
                  title: 'Network Affinity',
                  value: 'Timezone and Locale synced to Jakarta cluster.',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF0369A1)),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Once confirmed, this identity will be locked to your active session to ensure long-term persistence and anti-correlation.',
                          style: TextStyle(
                            color: Color(0xFF0C4A6E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
