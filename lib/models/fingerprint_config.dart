import 'dart:convert';
import 'dart:math';

part 'fingerprint_config.g.dart';

/// Geolocation configuration
class GeolocationConfig {
  final double latitude;
  final double longitude;
  final double accuracy;
  
  const GeolocationConfig({
    required this.latitude,
    required this.longitude,
    this.accuracy = 50.0,
  });
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
  };
  
  factory GeolocationConfig.fromJson(Map<String, dynamic> json) {
    return GeolocationConfig(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      accuracy: json['accuracy'] as double? ?? 50.0,
    );
  }
}

/// Screen resolution configuration
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
  final WebGLConfig webglConfig;
  final String canvasNoiseSalt;
  final bool webrtcEnabled;
  final String timezone;
  final GeolocationConfig? geolocation;
  
  const FingerprintConfig({
    required this.userAgent,
    required this.platform,
    required this.language,
    required this.hardwareConcurrency,
    required this.deviceMemory,
    required this.screenResolution,
    required this.webglConfig,
    required this.canvasNoiseSalt,
    this.webrtcEnabled = true,
    this.timezone = 'Asia/Jakarta',
    this.geolocation,
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
      'geolocation': geolocation?.toJson(),
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
      timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
      webglConfig: WebGLConfig.fromJson(
        json['webglConfig'] as Map<String, dynamic>,
      ),
      canvasNoiseSalt: json['canvasNoiseSalt'] as String,
      webrtcEnabled: json['webrtcEnabled'] as bool? ?? true,
      geolocation: json['geolocation'] != null 
        ? GeolocationConfig.fromJson(json['geolocation'] as Map<String, dynamic>)
        : null,
    );
  }
  
  FingerprintConfig copyWith({
    String? userAgent,
    String? platform,
    String? language,
    int? hardwareConcurrency,
    int? deviceMemory,
    ScreenResolution? screenResolution,
    WebGLConfig? webglConfig,
    String? canvasNoiseSalt,
    bool? webrtcEnabled,
    String? timezone,
    GeolocationConfig? geolocation,
  }) {
    return FingerprintConfig(
      userAgent: userAgent ?? this.userAgent,
      platform: platform ?? this.platform,
      language: language ?? this.language,
      hardwareConcurrency: hardwareConcurrency ?? this.hardwareConcurrency,
      deviceMemory: deviceMemory ?? this.deviceMemory,
      screenResolution: screenResolution ?? this.screenResolution,
      webglConfig: webglConfig ?? this.webglConfig,
      canvasNoiseSalt: canvasNoiseSalt ?? this.canvasNoiseSalt,
      webrtcEnabled: webrtcEnabled ?? this.webrtcEnabled,
      timezone: timezone ?? this.timezone,
      geolocation: geolocation ?? this.geolocation,
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
    
    // Normalization logic for Mobile vs Desktop
    final isMobileProfile = random.nextBool();
    
    // Default desktop profiles
    var resolutions = [
      ScreenResolution(width: 1920, height: 1080, colorDepth: 24),
      ScreenResolution(width: 2560, height: 1440, colorDepth: 24),
      ScreenResolution(width: 1366, height: 768, colorDepth: 24),
    ];
    
    var userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ];
    
    var cpuCores = [8, 12, 16];
    var ramSizes = [8, 16, 32];
    var platform = 'Win32';

    if (isMobileProfile) {
      resolutions = [
        ScreenResolution(width: 390, height: 844, colorDepth: 32), // iPhone 12/13/14
        ScreenResolution(width: 414, height: 896, colorDepth: 32), // iPhone X Max
        ScreenResolution(width: 360, height: 800, colorDepth: 24), // Generic Android
      ];
      userAgents = [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
      ];
      cpuCores = [6, 8];
      ramSizes = [4, 6, 8];
      platform = userAgents[0].contains('iPhone') ? 'iPhone' : 'Linux armv81';
    } else {
        platform = userAgents[0].contains('Macintosh') ? 'MacIntel' : 'Win32';
    }

    final selectedUa = userAgents[random.nextInt(userAgents.length)];
    if(selectedUa.contains('iPhone')) { platform = 'iPhone'; }
    else if(selectedUa.contains('Android')) { platform = 'Linux armv81'; }
    else if(selectedUa.contains('Macintosh')) { platform = 'MacIntel'; }
    else { platform = 'Win32'; }

    // Random WebGL vendors
    final webglVendors = isMobileProfile ? [
       WebGLConfig(vendor: 'Apple Inc.', renderer: 'Apple GPU'),
       WebGLConfig(vendor: 'Qualcomm', renderer: 'Adreno (TM) 650'),
    ] : [
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
    
    return FingerprintConfig(
      userAgent: selectedUa,
      platform: platform,
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

