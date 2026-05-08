enum RiskLevel { low, medium, high, critical }

class ProfileHealth {
  final String profileId;
  final double score; // 0-100, 100 is perfect
  final RiskLevel risk;
  final List<String> issues;
  final DateTime lastUpdated;
  final int hourlyRotationCount;

  ProfileHealth({
    required this.profileId,
    required this.score,
    required this.risk,
    required this.issues,
    required this.lastUpdated,
    this.hourlyRotationCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'score': score,
    'risk': risk.name,
    'issues': issues,
    'lastUpdated': lastUpdated.toIso8601String(),
    'hourlyRotationCount': hourlyRotationCount,
  };

  factory ProfileHealth.fromJson(Map<String, dynamic> json) => ProfileHealth(
    profileId: json['profileId'],
    score: (json['score'] ?? 100.0).toDouble(),
    risk: RiskLevel.values.firstWhere((e) => e.name == json['risk'], orElse: () => RiskLevel.low),
    issues: List<String>.from(json['issues'] ?? []),
    lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    hourlyRotationCount: json['hourlyRotationCount'] ?? 0,
  );
}
