/// IP metadata returned by ip-api.com.
/// Immutable value object — no business logic.
class IpInfo {
  final String ip;
  final String? country;
  final String? regionName;
  final String? isp;
  final bool isProxy;
  final int? latencyMs;

  const IpInfo({
    required this.ip,
    this.country,
    this.regionName,
    this.isp,
    this.isProxy = false,
    this.latencyMs,
  });

  factory IpInfo.fromJson(Map<String, dynamic> json, {int? latency}) {
    return IpInfo(
      ip: json['query'] as String? ?? '',
      country: json['country'] as String?,
      regionName: json['regionName'] as String?,
      isp: json['isp'] as String?,
      isProxy: json['proxy'] == true || json['hosting'] == true,
      latencyMs: latency,
    );
  }

  @override
  String toString() => 'IpInfo($ip, $country, $isp)';
}
