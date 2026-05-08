import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../identity_assembly_controller.dart';
import 'package:sec_tunnel/services/fingerprint/identity_system/device_blueprints.dart';

class FamilySelectionGrid extends StatelessWidget {
  const FamilySelectionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IdentityAssemblyController>();
    final families = DeviceBlueprints.families.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Device Family',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a manufacturer ecosystem to begin assembling your identity.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: families.length,
            itemBuilder: (context, index) {
              final family = families[index];
              final isSelected = controller.selectedFamily == family;
              
              return InkWell(
                onTap: () => controller.selectFamily(family),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconForFamily(family),
                        size: 32,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        family.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_isPopular(family))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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

  IconData _getIconForFamily(String family) {
    switch (family.toLowerCase()) {
      case 'samsung': return Icons.edgesensor_high_rounded;
      case 'pixel': return Icons.phone_android_rounded;
      case 'xiaomi':
      case 'redmi': return Icons.phonelink_setup_rounded;
      default: return Icons.smartphone_rounded;
    }
  }

  bool _isPopular(String family) {
    return ['samsung', 'xiaomi', 'oppo', 'vivo'].contains(family.toLowerCase());
  }
}
