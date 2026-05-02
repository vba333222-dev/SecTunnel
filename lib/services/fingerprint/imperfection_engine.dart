import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:SecTunnel/services/fingerprint/session_seed.dart';

/// The Imperfection Engine applies controlled, deterministic jitter and noise.
/// 
/// It relies solely on the global `SessionSeed` and input parameters to ensure
/// pure deterministic math, avoiding `Math.random()` entirely while still
/// generating profile-consistent variations that evade detection.
class ImperfectionEngine {
  
  /// Applies a deterministic jitter to a [base] value by a given [percentage] (0.0 to 1.0).
  /// The [salt] is used to differentiate the jitter from other properties.
  static double applyJitter(double base, double percentage, String salt) {
    final int hash = _generateHash(salt);
    // Convert hash to a pseudo-random value between -1.0 and 1.0
    final double normalized = ((hash % 20000) - 10000) / 10000.0;
    
    final double jitterAmount = base * percentage * normalized;
    return base + jitterAmount;
  }

  /// Generates a deterministic noise salt string based on a [prefix] and the SessionSeed.
  static String generateNoiseSalt(String prefix) {
    final seed = SessionSeed.getSessionSeed();
    final raw = '\$prefix:\$seed';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// Applies a deterministic rounding to an integer [value] using a specified [step].
  /// The [salt] ensures the rounding offset is deterministic but looks natural.
  static int applyRounding(int value, int step, String salt) {
    if (step <= 0) return value;
    final int hash = _generateHash(salt);
    // Determine the offset based on the hash and the step size
    final int offset = hash % step;
    
    // Find the nearest multiple of `step`
    final int baseMultiple = (value ~/ step) * step;
    return baseMultiple + offset;
  }

  /// Helper to generate an integer hash from a salt and the session seed.
  static int _generateHash(String salt) {
    final seed = SessionSeed.getSessionSeed();
    final raw = '\$salt:\$seed';
    final digest = md5.convert(utf8.encode(raw));
    // Use the first 8 bytes of the MD5 digest to form an integer
    var hash = 0;
    for (var i = 0; i < 8; i++) {
      hash = (hash << 8) | digest.bytes[i];
    }
    return hash.abs();
  }
}
