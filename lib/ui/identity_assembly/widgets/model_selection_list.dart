import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../identity_assembly_controller.dart';
import 'package:sec_tunnel/services/fingerprint/identity_system/device_blueprints.dart';

class ModelSelectionList extends StatelessWidget {
  const ModelSelectionList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IdentityAssemblyController>();
    if (controller.selectedFamily == null) return const SizedBox.shrink();

    final blueprints = DeviceBlueprints.families[controller.selectedFamily!] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              controller.selectedFamily!.toUpperCase(),
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
          'Select Model',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: blueprints.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final blueprint = blueprints[index];
              final modelName = blueprint.model;
              final isSelected = controller.selectedModel == modelName;

              return InkWell(
                onTap: () => controller.selectModel(modelName),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modelName,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${blueprint.cpu.model} • ${blueprint.gpu.renderer} • ${blueprint.ram}GB',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF2563EB))
                      else
                        const Icon(Icons.radio_button_off, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
