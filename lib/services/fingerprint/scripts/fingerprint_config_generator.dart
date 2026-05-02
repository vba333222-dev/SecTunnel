import 'dart:math';
import 'package:SecTunnel/models/fingerprint_config.dart';
import 'device_profile_repository.dart';
import 'distribution_engine.dart';
import 'statistical_validator.dart';

class FingerprintConfigGenerator {
  static FingerprintConfig generateConfig(int sessionSeed) {
    // 8. INTEGRATION WITH EXISTING SYSTEM
    // Replace random config generation with profile-based config generation
    DeviceProfile profile = DistributionEngine.selectProfile(sessionSeed);
    
    if (!StatisticalValidator.validate(profile)) {
      print('[STAT] Fallback to standard profile due to validation failure');
      profile = DeviceProfileRepository.profiles.firstWhere((p) => p.id == 'win10_chrome_standard');
    }

    final random = Random(sessionSeed);
    
    // 5. SOFT VARIATION
    // Allow slight variation inside profile to ensure non-identical footprints
    final dprVariation = (random.nextDouble() - 0.5) * 0.04; // ±0.02
    final finalDpr = double.parse((profile.devicePixelRatio + dprVariation).toStringAsFixed(2));
    
    final widthVariation = random.nextInt(3) - 1; // -1 to 1 pixel
    final finalWidth = profile.screenWidth + widthVariation;
    
    final heightVariation = random.nextInt(3) - 1; // -1 to 1 pixel
    final finalHeight = profile.screenHeight + heightVariation;

    // 7. PROFILE LOCKING
    // Values are derived deterministically per session
    return FingerprintConfig(
      sessionBoundSeed: sessionSeed,
      userAgent: profile.userAgent,
      platform: profile.platform,
      hardwareConcurrency: profile.hardwareConcurrency,
      deviceMemory: profile.deviceMemory,
      devicePixelRatio: finalDpr,
      screenWidth: finalWidth,
      screenHeight: finalHeight,
      webglVendor: profile.webglVendor,
      webglRenderer: profile.webglRenderer,
      timezone: profile.timezone,
      language: profile.language,
      isMobile: profile.type == 'mobile',
    );
  }
}
