import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../identity_assembly_controller.dart';

class RegionSelectionGrid extends StatelessWidget {
  const RegionSelectionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IdentityAssemblyController>();
    
    final regions = [
      {'id': 'ID', 'name': 'Jakarta', 'desc': 'Primary Cluster (Telkomsel/Indosat)'},
      {'id': 'ID-SB', 'name': 'Surabaya', 'desc': 'East Java Cluster'},
      {'id': 'ID-BD', 'name': 'Bandung', 'desc': 'West Java Cluster'},
      {'id': 'ID-MD', 'name': 'Medan', 'desc': 'Sumatra Cluster'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Region Cluster',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Regional clusters ensure your timezone, locale, and latency match your mobile proxy location.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: regions.length,
            itemBuilder: (context, index) {
              final region = regions[index];
              final isSelected = controller.selectedRegion == region['id'];
              
              return InkWell(
                onTap: () => controller.selectRegion(region['id']!),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region['name']!,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              region['desc']!,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
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
