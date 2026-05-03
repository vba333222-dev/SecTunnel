import 'package:flutter/material.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/device_preset.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/preset_repository.dart';

class PresetSelectorWidget extends StatelessWidget {
  final DevicePreset? selectedPreset;
  final ValueChanged<DevicePreset> onPresetSelected;

  const PresetSelectorWidget({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            final presets = PresetRepository.presets;
            final Map<String, List<DevicePreset>> grouped = {};
            for (var p in presets) {
              grouped.putIfAbsent(p.category, () => []).add(p);
            }

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Device Preset',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final category = grouped.keys.elementAt(index);
                      final categoryPresets = grouped[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...categoryPresets.map((p) => ListTile(
                                leading: Icon(
                                  category == 'mobile'
                                      ? Icons.smartphone
                                      : category == 'laptop'
                                          ? Icons.laptop_mac
                                          : Icons.desktop_windows,
                                  color: Colors.grey[400],
                                ),
                                title: Text(p.name,
                                    style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                  '${p.platform} • ${p.deviceMemory}GB RAM • ${p.screenWidth}x${p.screenHeight}',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                trailing: selectedPreset?.id == p.id
                                    ? Icon(Icons.check_circle,
                                        color: Colors.blue[600])
                                    : null,
                                onTap: () {
                                  onPresetSelected(p);
                                  Navigator.pop(context);
                                },
                              )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPicker(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  selectedPreset?.category == 'mobile'
                      ? Icons.smartphone
                      : selectedPreset?.category == 'laptop'
                          ? Icons.laptop_mac
                          : Icons.devices,
                  key: ValueKey<String>(selectedPreset?.category ?? 'none'),
                  color: Colors.blue[600],
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Preset',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey<String>(selectedPreset?.id ?? 'none'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPreset?.name ?? 'Select a preset',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedPreset != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${selectedPreset!.platform} • ${selectedPreset!.deviceMemory}GB RAM • ${selectedPreset!.screenWidth}x${selectedPreset!.screenHeight}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          ],
        ),
      ),
    )));
  }
}
