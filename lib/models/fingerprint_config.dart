import 'dart:convert';
import 'dart:math';
import 'package:sec_tunnel/services/fingerprint/session_seed.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/device_preset.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/preset_repository.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/preset_variation.dart';

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
      vendor: preset.vendor, 
      language: preset.locale,
      hardwareConcurrency: preset.hardwareConcurrency,
      deviceMemory: preset.deviceMemory,
      maxTouchPoints: preset.maxTouchPoints,
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
    // Better strategy: Pick a random high-fidelity preset and apply variation
    final random = Random();
    final presets = PresetRepository.presets;
    final basePreset = presets[random.nextInt(presets.length)];
    
    // Apply variation with a random seed
    final variedPreset = PresetVariation.applyVariation(basePreset, random.nextInt(1000000));
    
    return FingerprintConfig.fromPreset(variedPreset);
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

