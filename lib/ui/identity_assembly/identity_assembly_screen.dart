import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'identity_assembly_controller.dart';
import 'widgets/family_selection_grid.dart';
import 'widgets/model_selection_list.dart';
import 'widgets/region_selection_grid.dart';
import 'widgets/identity_preview_panel.dart';
import 'widgets/safe_variant_selector.dart';
import 'widgets/identity_review_step.dart';

class IdentityAssemblyScreen extends StatelessWidget {
  const IdentityAssemblyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IdentityAssemblyController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const CloseButton(color: Color(0xFF1E293B)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identity Assembly',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Consumer<IdentityAssemblyController>(
                builder: (context, controller, _) {
                  return Text(
                    'Step ${controller.currentStep + 1} of 5',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Consumer<IdentityAssemblyController>(
                  builder: (context, controller, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: controller.riskColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: controller.riskColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: controller.riskColor),
                          const SizedBox(width: 6),
                          Text(
                            controller.riskLabel,
                            style: TextStyle(
                              color: controller.riskColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            // Main Assembly Area
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (context.watch<IdentityAssemblyController>().currentStep + 1) / 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF2563EB),
                    minHeight: 2,
                  ),
                  Expanded(
                    child: Consumer<IdentityAssemblyController>(
                      builder: (context, controller, _) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: _buildStepContent(controller.currentStep),
                        );
                      },
                    ),
                  ),
                  // Footer Actions
                  _buildFooter(context),
                ],
              ),
            ),
            // Preview Panel (Desktop Only)
            const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
            const Expanded(
              flex: 1,
              child: IdentityPreviewPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return const FamilySelectionGrid();
      case 1:
        return const ModelSelectionList();
      case 2:
        return const RegionSelectionGrid();
      case 3:
        return const SafeVariantSelector();
      case 4:
        return const IdentityReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter(BuildContext context) {
    final controller = context.watch<IdentityAssemblyController>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.currentStep > 0)
            OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          
          ElevatedButton(
            onPressed: _canProceed(controller)
                ? () {
                    if (controller.currentStep == 4) {
                      Navigator.pop(context, controller.currentPreview);
                    } else {
                      controller.nextStep();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
            ),
            child: Text(controller.currentStep == 4 ? 'Confirm Identity' : 'Continue'),
          ),
        ],
      ),
    );
  }

  bool _canProceed(IdentityAssemblyController controller) {
    switch (controller.currentStep) {
      case 0:
        return controller.selectedFamily != null;
      case 1:
        return controller.selectedModel != null;
      case 2:
        return true; // Region always has default
      default:
        return true;
    }
  }
}
