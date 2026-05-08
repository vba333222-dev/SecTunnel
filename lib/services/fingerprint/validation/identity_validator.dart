import 'package:sec_tunnel/models/identity/master_identity.dart';

class IdentityValidator {
  static ValidationResult validate(MasterIdentity identity) {
    final List<String> errors = [];

    // 1. Engine Check
    if (identity.engine.name != 'Blink') {
      errors.add('Invalid Engine: Only Blink/Chromium is supported.');
    }

    // 2. OS vs GPU Vendor Coherence
    final os = identity.platform.os;
    final gpuVendor = identity.hardware.gpu.vendor;

    if (os == 'Android') {
      if (gpuVendor.contains('NVIDIA') || gpuVendor.contains('Intel')) {
        errors.add('Hardware Inconsistency: Android devices do not use $gpuVendor GPUs.');
      }
    }

    if (os == 'Windows') {
      if (gpuVendor.contains('ARM') || gpuVendor.contains('Mali')) {
        errors.add('Hardware Inconsistency: Windows Desktop rarely uses $gpuVendor GPUs.');
      }
    }

    // 3. Platform vs Architecture Coherence
    if (os == 'Android' && identity.platform.architecture != 'arm64') {
      errors.add('Architecture Mismatch: Modern Android 14+ must be arm64.');
    }

    // 4. Mobile vs Touch Coherence
    if (identity.platform.isMobile && identity.platform.deviceClass == 'desktop') {
      errors.add('Identity Conflict: Mobile flag set for Desktop device class.');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}
