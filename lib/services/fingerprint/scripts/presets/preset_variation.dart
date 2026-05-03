// ignore_for_file: avoid_print
import 'device_preset.dart';

class PresetVariation {
  static DevicePreset applyVariation(DevicePreset preset, int seed) {
    // Basic PRNG
    int rnd(int max) {
       var s = seed ^ (seed << 13);
       s ^= s >> 17;
       s ^= s << 5;
       seed = s;
       return (s.abs() % max);
    }
    
    // Vary DPR by +/- 0.02
    double varDpr = preset.devicePixelRatio + ((rnd(40) - 20) / 1000.0);
    
    // Vary resolution by small amounts (only for desktops to simulate window resizing, usually not mobile screens)
    int varVW = preset.viewportWidth;
    int varVH = preset.viewportHeight;
    if (preset.category != 'mobile') {
       varVW += (rnd(100) - 50);
       varVH += (rnd(100) - 50);
    }
    
    if (varVW > preset.screenWidth) varVW = preset.screenWidth;
    if (varVH > preset.screenHeight) varVH = preset.screenHeight;

    print("[PRESET] Variation applied to \${preset.id}");

    return DevicePreset(
      id: preset.id,
      name: preset.name,
      category: preset.category,
      userAgent: preset.userAgent,
      platform: preset.platform,
      hardwareConcurrency: preset.hardwareConcurrency,
      deviceMemory: preset.deviceMemory,
      devicePixelRatio: varDpr,
      screenWidth: preset.screenWidth,
      screenHeight: preset.screenHeight,
      viewportWidth: varVW,
      viewportHeight: varVH,
      gpuVendor: preset.gpuVendor,
      gpuRenderer: preset.gpuRenderer,
      webglVersion: preset.webglVersion,
      touchPoints: preset.touchPoints,
      timezone: preset.timezone,
      locale: preset.locale,
      fonts: preset.fonts,
      mediaDevices: preset.mediaDevices,
      codecs: preset.codecs,
      behaviorProfile: preset.behaviorProfile,
      networkProfile: preset.networkProfile,
      weight: preset.weight,
    );
  }
}
