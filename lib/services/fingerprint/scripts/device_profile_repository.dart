class DeviceProfile {
  final String id;
  final String type; // desktop, laptop, mobile
  final String userAgent;
  final String platform;
  final int hardwareConcurrency;
  final int deviceMemory;
  final double devicePixelRatio;
  final int screenWidth;
  final int screenHeight;
  final String webglVendor;
  final String webglRenderer;
  final String timezone;
  final String language;
  final double weight; 

  const DeviceProfile({
    required this.id,
    required this.type,
    required this.userAgent,
    required this.platform,
    required this.hardwareConcurrency,
    required this.deviceMemory,
    required this.devicePixelRatio,
    required this.screenWidth,
    required this.screenHeight,
    required this.webglVendor,
    required this.webglRenderer,
    required this.timezone,
    required this.language,
    required this.weight,
  });
}

class DeviceProfileRepository {
  static const List<DeviceProfile> profiles = [
    DeviceProfile(
      id: 'win10_chrome_standard',
      type: 'laptop',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      platform: 'Win32',
      hardwareConcurrency: 8,
      deviceMemory: 8,
      devicePixelRatio: 1.0,
      screenWidth: 1920,
      screenHeight: 1080,
      webglVendor: 'Google Inc. (Intel)',
      webglRenderer: 'ANGLE (Intel, Intel(R) Iris(R) Xe Graphics Direct3D11 vs_5_0 ps_5_0, D3D11)',
      timezone: 'America/Chicago',
      language: 'en-US',
      weight: 45.0,
    ),
    DeviceProfile(
      id: 'win10_chrome_gaming',
      type: 'desktop',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      platform: 'Win32',
      hardwareConcurrency: 16,
      deviceMemory: 16,
      devicePixelRatio: 1.0,
      screenWidth: 2560,
      screenHeight: 1440,
      webglVendor: 'Google Inc. (NVIDIA)',
      webglRenderer: 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3070 Direct3D11 vs_5_0 ps_5_0, D3D11)',
      timezone: 'America/New_York',
      language: 'en-US',
      weight: 15.0,
    ),
    DeviceProfile(
      id: 'macbook_pro_m2',
      type: 'laptop',
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      platform: 'MacIntel',
      hardwareConcurrency: 8,
      deviceMemory: 8,
      devicePixelRatio: 2.0,
      screenWidth: 1440,
      screenHeight: 900,
      webglVendor: 'Google Inc. (Apple)',
      webglRenderer: 'ANGLE (Apple, Apple M2, OpenGL 4.1)',
      timezone: 'America/Los_Angeles',
      language: 'en-US',
      weight: 20.0,
    ),
    DeviceProfile(
      id: 'iphone_14_pro',
      type: 'mobile',
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
      platform: 'iPhone',
      hardwareConcurrency: 6,
      deviceMemory: 6,
      devicePixelRatio: 3.0,
      screenWidth: 393,
      screenHeight: 852,
      webglVendor: 'Apple Inc.',
      webglRenderer: 'Apple GPU',
      timezone: 'America/New_York',
      language: 'en-US',
      weight: 15.0,
    ),
    DeviceProfile(
      id: 'android_galaxy_s23',
      type: 'mobile',
      userAgent: 'Mozilla/5.0 (Linux; Android 13; SM-S911B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
      platform: 'Linux aarch64',
      hardwareConcurrency: 8,
      deviceMemory: 8,
      devicePixelRatio: 3.0,
      screenWidth: 360,
      screenHeight: 780,
      webglVendor: 'Qualcomm',
      webglRenderer: 'Adreno (TM) 740',
      timezone: 'America/Chicago',
      language: 'en-US',
      weight: 5.0,
    )
  ];
}
