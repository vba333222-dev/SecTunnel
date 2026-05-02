class IpInfo {
  final String ip;
  final String? country;
  final String? regionName;
  final String? isp;
  final bool isProxy;
  final int? latencyMs;

  IpInfo({
    required this.ip,
    this.country,
    this.regionName,
    this.isp,
    this.isProxy = false,
    this.latencyMs,
  });

  factory IpInfo.fromJson(Map<String, dynamic> json, {int? latency}) {
    return IpInfo(
      ip: json['query'] ?? '',
      country: json['country'],
      regionName: json['regionName'],
      isp: json['isp'],
      isProxy: json['proxy'] == true || json['hosting'] == true,
      latencyMs: latency,
    );
  }
}
