class NetworkAffinity {
  final String profileId;
  final String primaryAsn;      // The ASN this profile is "born" into
  final String primaryCarrier;  // e.g., 'Telkomsel'
  final String currentIp;
  final DateTime lastSeen;
  final int totalRotations;
  final double consistencyScore; // 1.0 = always on same ASN, 0.0 = total chaos

  NetworkAffinity({
    required this.profileId,
    required this.primaryAsn,
    required this.primaryCarrier,
    required this.currentIp,
    required this.lastSeen,
    this.totalRotations = 0,
    this.consistencyScore = 1.0,
  });

  factory NetworkAffinity.initial(String profileId, String asn, String carrier, String ip) {
    return NetworkAffinity(
      profileId: profileId,
      primaryAsn: asn,
      primaryCarrier: carrier,
      currentIp: ip,
      lastSeen: DateTime.now(),
    );
  }

  NetworkAffinity copyWith({
    String? currentIp,
    DateTime? lastSeen,
    int? totalRotations,
    double? consistencyScore,
  }) {
    return NetworkAffinity(
      profileId: profileId,
      primaryAsn: primaryAsn,
      primaryCarrier: primaryCarrier,
      currentIp: currentIp ?? this.currentIp,
      lastSeen: lastSeen ?? this.lastSeen,
      totalRotations: totalRotations ?? this.totalRotations,
      consistencyScore: consistencyScore ?? this.consistencyScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'primaryAsn': primaryAsn,
    'primaryCarrier': primaryCarrier,
    'currentIp': currentIp,
    'lastSeen': lastSeen.toIso8601String(),
    'totalRotations': totalRotations,
    'consistencyScore': consistencyScore,
  };

  factory NetworkAffinity.fromJson(Map<String, dynamic> json) => NetworkAffinity(
    profileId: json['profileId'],
    primaryAsn: json['primaryAsn'],
    primaryCarrier: json['primaryCarrier'],
    currentIp: json['currentIp'],
    lastSeen: DateTime.parse(json['lastSeen']),
    totalRotations: json['totalRotations'] ?? 0,
    consistencyScore: (json['consistencyScore'] ?? 1.0).toDouble(),
  );
}
