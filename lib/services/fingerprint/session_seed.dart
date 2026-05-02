import 'dart:math';

/// A global session seed used by the ImperfectionEngine.
/// 
/// Generates a stable seed per session that remains constant during the session.
/// This ensures all spoof modules derive their deterministic "imperfections"
/// from the same baseline entropy.
class SessionSeed {
  static int? _seed;

  /// Returns the global session seed.
  /// If it hasn't been generated yet, it generates and stores one.
  static int getSessionSeed() {
    if (_seed == null) {
      // Initialize the session seed using a secure random generator
      // This is the ONLY place where a random source is used for the current session.
      final secureRandom = Random.secure();
      _seed = secureRandom.nextInt(1000000) + 1;
    }
    return _seed!;
  }

  /// Manually override the session seed (useful for testing or specific profiles).
  static void setSessionSeed(int seed) {
    _seed = seed;
  }
}
