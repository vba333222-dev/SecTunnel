import 'package:flutter/material.dart';
import 'package:sec_tunnel/models/identity/master_identity.dart';
import 'package:sec_tunnel/services/fingerprint/identity_system/identity_factory.dart';

class IdentityAssemblyController extends ChangeNotifier {
  int currentStep = 0;
  
  String? selectedFamily;
  String? selectedModel;
  String selectedRegion = 'ID';
  
  // Safe Variants
  int? selectedRam;
  String? selectedAndroidVersion;
  
  MasterIdentity? currentPreview;

  void nextStep() {
    if (currentStep < 4) {
      currentStep++;
      _updatePreview();
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void selectFamily(String family) {
    selectedFamily = family;
    selectedModel = null; // Reset model on family change
    _updatePreview();
    notifyListeners();
  }

  void selectModel(String model) {
    selectedModel = model;
    _updatePreview();
    notifyListeners();
  }

  void selectRegion(String region) {
    selectedRegion = region;
    _updatePreview();
    notifyListeners();
  }

  void _updatePreview() {
    if (selectedFamily != null && selectedModel != null) {
      try {
        currentPreview = IdentityFactory.generate(
          family: selectedFamily!,
          model: selectedModel!,
          region: selectedRegion,
          seed: 'preview_seed_${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (e) {
        currentPreview = null;
      }
    } else {
      currentPreview = null;
    }
  }

  double get realismScore {
    if (currentPreview == null) return 0.0;
    // Simple heuristic for now: ID region + Mobile device = High realism for SecTunnel
    double score = 0.8;
    if (selectedRegion == 'ID') score += 0.1;
    if (currentPreview!.platform.isMobile) score += 0.1;
    return score.clamp(0.0, 1.0);
  }

  String get riskLabel {
    final score = realismScore;
    if (score > 0.9) return 'LOW RISK';
    if (score > 0.7) return 'MEDIUM RISK';
    return 'HIGH RISK';
  }

  Color get riskColor {
    final score = realismScore;
    if (score > 0.9) return Colors.green;
    if (score > 0.7) return Colors.orange;
    return Colors.red;
  }
}
