// ignore_for_file: avoid_print
import 'device_preset.dart';

class PresetValidator {
  static bool validate(DevicePreset preset) {
    bool isValid = true;
    
    // Apple Checks
    if (preset.platform.contains('Mac') || preset.platform.contains('iPhone')) {
      if (!preset.gpuVendor.contains('Apple') && !preset.gpuRenderer.contains('Apple')) {
         isValid = false;
      }
      if (!preset.userAgent.contains('Mac OS X')) {
         isValid = false;
      }
    }
    
    // Windows Checks
    if (preset.platform.contains('Win')) {
      if (preset.gpuVendor.contains('Apple')) {
         isValid = false;
      }
      if (!preset.gpuRenderer.contains('Direct3D') && !preset.gpuRenderer.contains('D3D11')) {
         isValid = false;
      }
    }
    
    // Mobile Checks
    if (preset.category == 'mobile') {
      if (preset.touchPoints <= 0) isValid = false;
      if (!preset.userAgent.contains('Mobile')) isValid = false;
      if (preset.devicePixelRatio < 1.5) isValid = false;
    }
    
    // Cross-layer mismatch
    if (preset.hardwareConcurrency < 4 && preset.behaviorProfile['latency'] == 'ultra_low') {
      isValid = false;
    }
    
    if (isValid) {
       print("[PRESET] Validation passed for \${preset.id}");
    } else {
       print("[PRESET] Validation FAILED for \${preset.id}");
    }
    
    return isValid;
  }
}
