import 'dart:math';
import 'device_profile_repository.dart';

class DistributionEngine {
  static DeviceProfile selectProfile(int sessionSeed) {
    // 1. DISTRIBUTION MODEL: Probability-based sampling
    final random = Random(sessionSeed);
    
    double totalWeight = 0;
    for (var profile in DeviceProfileRepository.profiles) {
      totalWeight += profile.weight;
    }
    
    double threshold = random.nextDouble() * totalWeight;
    double current = 0;
    
    DeviceProfile selected = DeviceProfileRepository.profiles.first;
    for (var profile in DeviceProfileRepository.profiles) {
      current += profile.weight;
      if (current >= threshold) {
        selected = profile;
        break;
      }
    }

    print('[STAT] Profile selected: \${selected.id}');
    print('[STAT] Distribution weight applied');
    
    return selected;
  }
}
