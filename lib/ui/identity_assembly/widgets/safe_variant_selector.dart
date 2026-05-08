import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../identity_assembly_controller.dart';

class SafeVariantSelector extends StatelessWidget {
  const SafeVariantSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IdentityAssemblyController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${controller.selectedFamily?.toUpperCase()} ${controller.selectedModel?.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748B)),
          ],
        ),
        const Text(
          'Safe Variants',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'These variants are locked to the physical hardware capabilities of your chosen device.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        _buildVariantCard(
          title: 'Memory Configuration',
          subtitle: 'Physical RAM capacity determines hardware concurrency signatures.',
          options: ['4GB', '6GB', '8GB', '12GB'],
          selected: '8GB',
        ),
        const SizedBox(height: 16),
        _buildVariantCard(
          title: 'OS Lifecycle',
          subtitle: 'Stable Android versions supported by this hardware cluster.',
          options: ['Android 13', 'Android 14', 'Android 15 (Beta)'],
          selected: 'Android 14',
        ),
      ],
    );
  }

  Widget _buildVariantCard({
    required String title,
    required String subtitle,
    required List<String> options,
    required String selected,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
