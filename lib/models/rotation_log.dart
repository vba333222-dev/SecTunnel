import 'package:SecTunnel/models/ip_info.dart';

/// Quality classification derived from IP scoring.
enum IpQuality {
  good,   // 80–100
  ok,     // 50–79
  bad,    // 0–49
  unknown;

  static IpQuality fromScore(int score) {
    if (score >= 80) return IpQuality.good;
    if (score >= 50) return IpQuality.ok;
    if (score > 0) return IpQuality.bad;
    return IpQuality.unknown;
  }

  String get label {
    switch (this) {
      case IpQuality.good:
        return 'GOOD';
      case IpQuality.ok:
        return 'OK';
      case IpQuality.bad:
        return 'BAD';
      case IpQuality.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Immutable record of a single rotation attempt.
class RotationLog {
  final String profileId;
  final DateTime timestamp;
  final String? oldIp;
  final String? newIp;
  final IpInfo? ipInfo;
  final int qualityScore;
  final IpQuality quality;
  final bool ipChanged;
  final bool isSuccess;
  final String? error;
  final Duration cooldownApplied;
  final int healthScoreAfter;

  const RotationLog({
    required this.profileId,
    required this.timestamp,
    this.oldIp,
    this.newIp,
    this.ipInfo,
    this.qualityScore = 0,
    this.quality = IpQuality.unknown,
    this.ipChanged = false,
    this.isSuccess = false,
    this.error,
    required this.cooldownApplied,
    required this.healthScoreAfter,
  });
}
