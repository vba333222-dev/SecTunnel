import 'dart:convert';
import 'dart:math';
import 'package:sec_tunnel/services/fingerprint/session_seed.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/device_preset.dart';

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
  final String vendor;
  final String language;
  final int hardwareConcurrency;
  final int deviceMemory;
  final int maxTouchPoints;
  final double devicePixelRatio;
  final ScreenResolution screenResolution;
  final WebGLConfig webglConfig;
  final String canvasNoiseSalt;
  final bool webrtcEnabled;
  final String timezone;
  final GeolocationConfig? geolocation;
  
  const FingerprintConfig({
    required this.userAgent,
    required this.platform,
    this.vendor = 'Google Inc.',
    required this.language,
    required this.hardwareConcurrency,
    required this.deviceMemory,
    this.maxTouchPoints = 0,
    this.devicePixelRatio = 1.0,
    required this.screenResolution,
    required this.webglConfig,
    required this.canvasNoiseSalt,
    this.webrtcEnabled = true,
    this.timezone = 'Asia/Jakarta',
    this.geolocation,
  });
  
  String get secChUa {
    if (userAgent.contains('Chrome/')) {
      final match = RegExp(r'Chrome\/([0-9]+)').firstMatch(userAgent);
      if (match != null) {
        final version = match.group(1);
        return '"Not_A Brand";v="8", "Chromium";v="$version", "Google Chrome";v="$version"';
      }
    }
    return '';
  }
  
  /// Returns a combined seed using the profile's salt and the global SessionSeed.
  /// This ensures deterministic variation that is unique per profile but
  /// changes across different app sessions.
  int get sessionBoundSeed => canvasNoiseSalt.hashCode ^ SessionSeed.getSessionSeed();
  
  Map<String, dynamic> toJson() {
    return {
      'userAgent': userAgent,
      'platform': platform,
      'vendor': vendor,
      'language': language,
      'hardwareConcurrency': hardwareConcurrency,
      'deviceMemory': deviceMemory,
      'maxTouchPoints': maxTouchPoints,
      'devicePixelRatio': devicePixelRatio,
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
      vendor: json['vendor'] as String? ?? 'Google Inc.',
      language: json['language'] as String,
      hardwareConcurrency: json['hardwareConcurrency'] as int,
      deviceMemory: json['deviceMemory'] as int,
      maxTouchPoints: json['maxTouchPoints'] as int? ?? 0,
      devicePixelRatio: (json['devicePixelRatio'] as num?)?.toDouble() ?? 1.0,
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
    String? vendor,
    String? language,
    int? hardwareConcurrency,
    int? deviceMemory,
    int? maxTouchPoints,
    double? devicePixelRatio,
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
      vendor: vendor ?? this.vendor,
      language: language ?? this.language,
      hardwareConcurrency: hardwareConcurrency ?? this.hardwareConcurrency,
      deviceMemory: deviceMemory ?? this.deviceMemory,
      maxTouchPoints: maxTouchPoints ?? this.maxTouchPoints,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
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
  /// Whether this config targets a mobile device
  bool get isMobile {
    final p = platform.toLowerCase();
    return p.contains('iphone') || p.contains('ipad') || p.contains('arm');
  }

  /// Whether this config targets a desktop device
  bool get isDesktop => !isMobile;

  factory FingerprintConfig.fromPreset(DevicePreset preset) {
    return FingerprintConfig(
      userAgent: preset.userAgent,
      platform: preset.platform,
      vendor: 'Google Inc.', // usually overriden if needed by scripts, but default to Google Inc.
      language: preset.locale,
      hardwareConcurrency: preset.hardwareConcurrency,
      deviceMemory: preset.deviceMemory,
      maxTouchPoints: preset.touchPoints,
      devicePixelRatio: preset.devicePixelRatio,
      screenResolution: ScreenResolution(
        width: preset.screenWidth,
        height: preset.screenHeight,
        colorDepth: 24,
      ),
      timezone: preset.timezone,
      webglConfig: WebGLConfig(
        vendor: preset.gpuVendor,
        renderer: preset.gpuRenderer,
      ),
      canvasNoiseSalt: _generateRandomSalt(),
      webrtcEnabled: false, // Defaulting to false for safety
    );
  }

  factory FingerprintConfig.random() {
    final random = Random();
    
    // Decide platform class first — all parameters derive from this
    final isMobileProfile = random.nextBool();
    
    // ── Resolution pools (device-class aware) ────────────
    late final List<ScreenResolution> resolutions;
    late final List<String> userAgents;
    late final List<int> cpuCores;
    late final List<int> ramSizes;
    late final List<WebGLConfig> webglPool;
    late final String vendor;
    late final int maxTouchPoints;
    late final double dpr;

    if (isMobileProfile) {
      resolutions = [
        const ScreenResolution(width: 390, height: 844, colorDepth: 32),
        const ScreenResolution(width: 414, height: 896, colorDepth: 32),
        const ScreenResolution(width: 360, height: 800, colorDepth: 24),
      ];
      userAgents = [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
      ];
      cpuCores = [6, 8];
      ramSizes = [4, 6, 8];
      webglPool = [
        const WebGLConfig(vendor: 'Apple Inc.', renderer: 'Apple GPU'),
        const WebGLConfig(vendor: 'Qualcomm', renderer: 'Adreno (TM) 650'),
      ];
      maxTouchPoints = 5;
      dpr = [2.0, 3.0][random.nextInt(2)];
    } else {
      resolutions = [
        const ScreenResolution(width: 1920, height: 1080, colorDepth: 24),
        const ScreenResolution(width: 2560, height: 1440, colorDepth: 24),
        const ScreenResolution(width: 1366, height: 768, colorDepth: 24),
      ];
      userAgents = [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ];
      cpuCores = [8, 12, 16];
      ramSizes = [8, 16, 32];
      webglPool = [
        const WebGLConfig(
          vendor: 'Google Inc. (NVIDIA)',
          renderer: 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0)',
        ),
        const WebGLConfig(
          vendor: 'Google Inc. (AMD)',
          renderer: 'ANGLE (AMD, AMD Radeon RX 6700 XT Direct3D11 vs_5_0 ps_5_0)',
        ),
        const WebGLConfig(
          vendor: 'Google Inc. (Intel)',
          renderer: 'ANGLE (Intel, Intel(R) UHD Graphics 630 Direct3D11 vs_5_0 ps_5_0)',
        ),
      ];
      maxTouchPoints = 0;
      dpr = [1.0, 1.25, 1.5, 2.0][random.nextInt(4)];
    }

    // ── Select UA → derive platform + vendor ─────────────
    final selectedUa = userAgents[random.nextInt(userAgents.length)];
    String platform;
    if (selectedUa.contains('iPhone')) {
      platform = 'iPhone';
      vendor = 'Apple Computer, Inc.';
    } else if (selectedUa.contains('Android')) {
      platform = 'Linux armv81';
      vendor = 'Google Inc.';
    } else if (selectedUa.contains('Macintosh')) {
      platform = 'MacIntel';
      vendor = 'Google Inc.';
    } else {
      platform = 'Win32';
      vendor = 'Google Inc.';
    }

    // ── Languages / Timezones ────────────────────────────
    final languages = ['en-US', 'en-GB', 'en-CA', 'id-ID'];
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
      vendor: vendor,
      language: languages[random.nextInt(languages.length)],
      hardwareConcurrency: cpuCores[random.nextInt(cpuCores.length)],
      deviceMemory: ramSizes[random.nextInt(ramSizes.length)],
      maxTouchPoints: maxTouchPoints,
      devicePixelRatio: dpr,
      screenResolution: resolutions[random.nextInt(resolutions.length)],
      timezone: timezones[random.nextInt(timezones.length)],
      webglConfig: webglPool[random.nextInt(webglPool.length)],
      canvasNoiseSalt: _generateRandomSalt(),
      webrtcEnabled: random.nextBool(),
    );
  }
  
  static String _generateRandomSalt() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Public alias so external callers (e.g. ProfileFormScreen) can generate
  /// a fresh canvas noise salt without triggering a full [FingerprintConfig.random].
  static String generateNewSalt() => _generateRandomSalt();
}

