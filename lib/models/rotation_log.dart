import 'package:SecTunnel/models/ip_info.dart';

class RotationLog {
  final String profileId;
  final DateTime timestamp;
  final String? oldIp;
  final String? newIp;
  final IpInfo? ipInfo;
  final int qualityScore;
  final String qualityLabel;
  final bool isChanged;
  final String status;
  final String? error;
  final Duration cooldownApplied;
  final int healthScoreAfter;

  RotationLog({
    required this.profileId,
    required this.timestamp,
    this.oldIp,
    this.newIp,
    this.ipInfo,
    this.qualityScore = 0,
    this.qualityLabel = 'UNKNOWN',
    this.isChanged = false,
    required this.status,
    this.error,
    required this.cooldownApplied,
    required this.healthScoreAfter,
  });
}
