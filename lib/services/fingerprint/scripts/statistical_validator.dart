// ignore_for_file: avoid_print
import 'device_profile_repository.dart';

class StatisticalValidator {
  static bool validate(DeviceProfile profile) {
    // 4. HARD CONSTRAINTS: Impossible combos rejected
    if (profile.platform.contains('Mac') && profile.webglRenderer.contains('Direct3D')) {
      print('[STAT] Validation Failed: Mac + Direct3D is impossible');
      return false;
    }
    
    if (profile.type == 'mobile' && profile.deviceMemory > 16) {
      print('[STAT] Validation Failed: Mobile + >16GB RAM is unrealistic');
      return false;
    }
    
    // 3. CORRELATED SAMPLING: Ensure correlations match
    if (profile.platform.contains('iPhone') && profile.devicePixelRatio < 2.0) {
      print('[STAT] Validation Failed: iPhone + low DPR is unrealistic');
      return false;
    }
    
    if (profile.platform.contains('Linux aarch64') && profile.webglVendor.contains('Apple')) {
      print('[STAT] Validation Failed: Android + Apple GPU is impossible');
      return false;
    }

    // 9. VALIDATION: Calculate anomaly score
    double anomalyScore = _calculateAnomalyScore(profile);
    if (anomalyScore > 0.8) {
      print('[STAT] Validation Failed: Anomaly score too high');
      return false;
    }
    
    print('[STAT] Profile validated');
    return true;
  }

  static double _calculateAnomalyScore(DeviceProfile profile) {
    double score = 0.0;
    if (profile.weight < 10.0) score += 0.3; // Rare profile
    if (profile.devicePixelRatio % 1.0 != 0 && profile.type == 'desktop') score += 0.4; // Fractional DPR on desktop
    if (profile.hardwareConcurrency > 16 && profile.type == 'laptop') score += 0.5; // Extreme laptop specs
    return score;
  }
}
