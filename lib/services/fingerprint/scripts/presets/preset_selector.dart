import 'device_preset.dart';
import 'preset_repository.dart';
import 'preset_variation.dart';
import 'preset_validator.dart';

class PresetSelector {
  static DevicePreset selectPreset(int seed, {String? categoryFilter}) {
    List<DevicePreset> candidates = PresetRepository.presets;
    
    if (categoryFilter != null) {
      candidates = candidates.where((p) => p.category == categoryFilter).toList();
    }
    
    if (candidates.isEmpty) {
      candidates = PresetRepository.presets;
    }
    
    // Total weight to ensure majority distribution
    int totalWeight = candidates.fold(0, (sum, item) => sum + item.weight);
    
    final rnd = (int max) {
       var s = seed ^ (seed << 13);
       s ^= s >> 17;
       s ^= s << 5;
       seed = s;
       return (s.abs() % max);
    };
    
    int randomValue = rnd(totalWeight);
    int currentWeight = 0;
    DevicePreset? selected;
    
    // Weighted selection ensures mid/low-end dominate the pool
    for (var preset in candidates) {
      currentWeight += preset.weight;
      if (randomValue < currentWeight) {
        selected = preset;
        break;
      }
    }
    
    selected ??= candidates.first;
    
    print("[PRESET] Loaded: \${selected.name} (Weight: \${selected.weight} / \${totalWeight})");
    
    DevicePreset varied = PresetVariation.applyVariation(selected, seed);
    
    if (!PresetValidator.validate(varied)) {
       return selected; 
    }
    
    return varied;
  }
}
