import 'dart:convert';
import 'dart:math';

class ScreenResolution {
  final int width;
  final int height;
  final int colorDepth;
  
  const ScreenResolution({
    required this.width,
    required this.height,
    required this.colorDepth,
  });
  
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'colorDepth': colorDepth,
  };
  
  factory ScreenResolution.fromJson(Map<String, dynamic> json) {
    return ScreenResolution(
      width: json['width'] as int,
      height: json['height'] as int,
      colorDepth: json['colorDepth'] as int,
    );
  }
}

class WebGLConfig {
  final String vendor;
  final String renderer;
  
  const WebGLConfig({
    required this.vendor,
    required this.renderer,
  });
  
  Map<String, dynamic> toJson() => {
    'vendor': vendor,
    'renderer': renderer,
  };
  
  factory WebGLConfig.fromJson(Map<String, dynamic> json) {
    return WebGLConfig(
      vendor: json['vendor'] as String,
      renderer: json['renderer'] as String,
    );
  }
}

class FingerprintConfig {
  final String userAgent;
  final String platform;
  final String language;
  final int hardwareConcurrency;
  final int deviceMemory;
  final ScreenResolution screenResolution;
  final String timezone;
  final WebGLConfig webglConfig;
  final String canvasNoiseSalt;
  final bool webrtcEnabled;
  
  const FingerprintConfig({
    required this.userAgent,
    required this.platform,
    required this.language,
    required this.hardwareConcurrency,
    required this.deviceMemory,
    required this.screenResolution,
    required this.timezone,
    required this.webglConfig,
    required this.canvasNoiseSalt,
    required this.webrtcEnabled,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userAgent': userAgent,
      'platform': platform,
      'language': language,
      'hardwareConcurrency': hardwareConcurrency,
      'deviceMemory': deviceMemory,
      'screenResolution': screenResolution.toJson(),
      'timezone': timezone,
      'webglConfig': webglConfig.toJson(),
      'canvasNoiseSalt': canvasNoiseSalt,
      'webrtcEnabled': webrtcEnabled,
    };
  }
  
  factory FingerprintConfig.fromJson(Map<String, dynamic> json) {
    return FingerprintConfig(
      userAgent: json['userAgent'] as String,
      platform: json['platform'] as String,
      language: json['language'] as String,
      hardwareConcurrency: json['hardwareConcurrency'] as int,
      deviceMemory: json['deviceMemory'] as int,
      screenResolution: ScreenResolution.fromJson(
        json['screenResolution'] as Map<String, dynamic>,
      ),
      timezone: json['timezone'] as String,
      webglConfig: WebGLConfig.fromJson(
        json['webglConfig'] as Map<String, dynamic>,
      ),
      canvasNoiseSalt: json['canvasNoiseSalt'] as String,
      webrtcEnabled: json['webrtcEnabled'] as bool,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory FingerprintConfig.fromJsonString(String jsonString) {
    return FingerprintConfig.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
  
  /// Generate a random fingerprint configuration
  factory FingerprintConfig.random() {
    final random = Random();
    
    // Random screen resolutions (common ones)
    final resolutions = [
      ScreenResolution(width: 1920, height: 1080, colorDepth: 24),
      ScreenResolution(width: 2560, height: 1440, colorDepth: 24),
      ScreenResolution(width: 1366, height: 768, colorDepth: 24),
      ScreenResolution(width: 1536, height: 864, colorDepth: 24),
      ScreenResolution(width: 1440, height: 900, colorDepth: 24),
    ];
    
    // Random user agents (Windows Chrome variants)
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ];
    
    // Random WebGL vendors
    final webglVendors = [
      WebGLConfig(
        vendor: 'Google Inc. (NVIDIA)',
        renderer: 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0)',
      ),
      WebGLConfig(
        vendor: 'Google Inc. (AMD)',
        renderer: 'ANGLE (AMD, AMD Radeon RX 6700 XT Direct3D11 vs_5_0 ps_5_0)',
      ),
      WebGLConfig(
        vendor: 'Google Inc. (Intel)',
        renderer: 'ANGLE (Intel, Intel(R) UHD Graphics 630 Direct3D11 vs_5_0 ps_5_0)',
      ),
    ];
    
    // Random languages
    final languages = ['en-US', 'en-GB', 'en-CA', 'id-ID'];
    
    // Random timezones
    final timezones = [
      'America/New_York',
      'Europe/London',
      'Asia/Jakarta',
      'America/Los_Angeles',
      'Asia/Singapore',
    ];
    
    // Random hardware specs
    final cpuCores = [4, 6, 8, 12, 16];
    final ramSizes = [4, 8, 16, 32];
    
    return FingerprintConfig(
      userAgent: userAgents[random.nextInt(userAgents.length)],
      platform: 'Win32',
      language: languages[random.nextInt(languages.length)],
      hardwareConcurrency: cpuCores[random.nextInt(cpuCores.length)],
      deviceMemory: ramSizes[random.nextInt(ramSizes.length)],
      screenResolution: resolutions[random.nextInt(resolutions.length)],
      timezone: timezones[random.nextInt(timezones.length)],
      webglConfig: webglVendors[random.nextInt(webglVendors.length)],
      canvasNoiseSalt: _generateRandomSalt(),
      webrtcEnabled: random.nextBool(),
    );
  }
  
  static String _generateRandomSalt() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
