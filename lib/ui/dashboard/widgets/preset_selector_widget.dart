import 'package:flutter/material.dart';
import 'package:sec_tunnel/models/identity/master_identity.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/master_preset_repository.dart';

class PresetSelectorWidget extends StatelessWidget {
  final MasterIdentity? selectedIdentity;
  final ValueChanged<MasterIdentity>? onIdentitySelected;
  final VoidCallback? onTap;

  const PresetSelectorWidget({
    super.key,
    required this.selectedIdentity,
    this.onIdentitySelected,
    this.onTap,
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
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            final presets = MasterPresetRepository.getPresets();

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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select Identity Profile',
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
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final identity = presets[index];
                      final isSelected = selectedIdentity?.id == identity.id;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            identity.platform.isMobile ? Icons.smartphone_rounded : Icons.laptop_windows_rounded,
                            color: isSelected ? Colors.blue[600] : Colors.grey[600],
                          ),
                        ),
                        title: Text(
                          identity.metadata.label.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${identity.engine.chromiumVersion} • ${identity.hardware.gpu.renderer}',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        trailing: isSelected ? Icon(Icons.check_circle, color: Colors.blue[600]) : null,
                        onTap: () {
                          onIdentitySelected?.call(identity);
                          Navigator.pop(context);
                        },
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
          onTap: onTap ?? () => _showPicker(context),
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
                  child: Icon(
                    selectedIdentity?.platform.isMobile ?? true ? Icons.smartphone_rounded : Icons.laptop_windows_rounded,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Identity Profile',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedIdentity?.metadata.label.toUpperCase() ?? 'Select Profile',
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedIdentity != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${selectedIdentity!.engine.name} • ${selectedIdentity!.platform.os} ${selectedIdentity!.platform.osVersion}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
