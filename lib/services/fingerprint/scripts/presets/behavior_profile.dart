class BehaviorProfile {
  static Map<String, dynamic> getProfile(String type) {
    switch (type) {
      case 'ultra_low':
        return {
          'latency': 'ultra_low',
          'scroll': 'smooth',
          'timing': 'stable',
          'jitter_factor': 0.1
        };
      case 'low':
        return {
          'latency': 'low',
          'scroll': 'smooth',
          'timing': 'stable',
          'jitter_factor': 0.3
        };
      case 'medium':
        return {
          'latency': 'medium',
          'scroll': 'standard',
          'timing': 'stable',
          'jitter_factor': 0.7
        };
      case 'high':
      case 'low_mid_android': // New specific profile for low-mid devices
        return {
          'latency': 'high',
          'scroll': 'uneven',
          'timing': 'jittery',
          'jitter_factor': 1.5,
          'micro_hesitation': true
        };
      case 'very_high':
        return {
          'latency': 'very_high',
          'scroll': 'stutter',
          'timing': 'erratic',
          'jitter_factor': 2.5,
          'micro_hesitation': true
        };
      default:
        return {
          'latency': 'medium',
          'scroll': 'standard',
          'timing': 'stable',
          'jitter_factor': 0.5
        };
    }
  }
}
