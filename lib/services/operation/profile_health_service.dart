import 'dart:math';
import 'package:sec_tunnel/models/operation/profile_health.dart';
import 'package:sec_tunnel/models/rotation_log.dart';

class ProfileHealthService {
  static final ProfileHealthService _instance = ProfileHealthService._internal();
  factory ProfileHealthService() => _instance;
  ProfileHealthService._internal();

  final Map<String, ProfileHealth> _healthCache = {};

  ProfileHealth getHealth(String profileId, List<RotationLog> logs) {
    if (_healthCache.containsKey(profileId)) {
      final cached = _healthCache[profileId]!;
      if (DateTime.now().difference(cached.lastUpdated).inMinutes < 5) {
        return cached;
      }
    }

    final health = _calculateHealth(profileId, logs);
    _healthCache[profileId] = health;
    return health;
  }

  ProfileHealth _calculateHealth(String profileId, List<RotationLog> logs) {
    double score = 100.0;
    List<String> issues = [];

    final now = DateTime.now();
    final lastHourLogs = logs.where((l) => now.difference(l.timestamp).inHours < 1).toList();
    final hourlyCount = lastHourLogs.length;

    // 1. Velocity Analysis (Hourly Rotation Count)
    if (hourlyCount > 10) {
      score -= 40;
      issues.add('Excessive rotation velocity ($hourlyCount/hr)');
    } else if (hourlyCount > 5) {
      score -= 15;
      issues.add('High rotation frequency');
    }

    // 2. Failure Rate
    if (lastHourLogs.isNotEmpty) {
      final failures = lastHourLogs.where((l) => !l.isSuccess).length;
      final failureRate = failures / lastHourLogs.length;
      if (failureRate > 0.5) {
        score -= 30;
        issues.add('High failure rate (${(failureRate * 100).toInt()}%)');
      }
    }

    // 3. ASN/Network Stability (Placeholder for Continuity check)
    // If Consistency Score from NetworkContinuityService is low, we would penalize here

    // Determine Risk Level
    RiskLevel risk = RiskLevel.low;
    if (score < 40) {
      risk = RiskLevel.critical;
    } else if (score < 60) {
      risk = RiskLevel.high;
    } else if (score < 85) {
      risk = RiskLevel.medium;
    }

    return ProfileHealth(
      profileId: profileId,
      score: max(0, score),
      risk: risk,
      issues: issues,
      lastUpdated: now,
      hourlyRotationCount: hourlyCount,
    );
  }
}
