class DevicePreset {
  final String id;
  final String name;
  final String category; // 'mobile', 'laptop', 'desktop'
  final String userAgent;
  final String platform;
  final int hardwareConcurrency;
  final int deviceMemory;
  final double devicePixelRatio;
  final int screenWidth;
  final int screenHeight;
  final int viewportWidth;
  final int viewportHeight;
  final String gpuVendor;
  final String gpuRenderer;
  final String webglVersion;
  final int touchPoints;
  final String timezone;
  final String locale;
  final List<String> fonts;
  final Map<String, dynamic> mediaDevices;
  final List<String> codecs;
  final Map<String, dynamic> behaviorProfile;
  final Map<String, dynamic> networkProfile;
  final int weight; // Higher weight = higher probability of selection

  DevicePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.userAgent,
    required this.platform,
    required this.hardwareConcurrency,
    required this.deviceMemory,
    required this.devicePixelRatio,
    required this.screenWidth,
    required this.screenHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.gpuVendor,
    required this.gpuRenderer,
    required this.webglVersion,
    required this.touchPoints,
    required this.timezone,
    required this.locale,
    required this.fonts,
    required this.mediaDevices,
    required this.codecs,
    required this.behaviorProfile,
    required this.networkProfile,
    required this.weight,
  });
}
