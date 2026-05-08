import 'dart:convert';
import 'dart:math';
import 'package:sec_tunnel/services/fingerprint/session_seed.dart';
import 'package:sec_tunnel/models/identity/master_identity.dart';

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
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 50.0,
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
  final String deviceClass;
  final String os;
  final String browserEngine;
  final String gpuFamily;
  final String cpu;
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
    required this.deviceClass,
    required this.os,
    required this.browserEngine,
    required this.gpuFamily,
    required this.cpu,
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
    final match = RegExp(r'Chrome\/([0-9]+)').firstMatch(userAgent);
    if (match != null) {
      final version = match.group(1);
      return '"Not_A Brand";v="8", "Chromium";v="$version", "Google Chrome";v="$version"';
    }
    return '';
  }

  String get secChUaMobile => isMobile ? '?1' : '?0';

  String get secChUaPlatform {
    final p = platform.toLowerCase();
    if (p.contains('win')) return '"Windows"';
    if (p.contains('mac')) return '"macOS"';
    if (p.contains('android')) return '"Android"';
    if (p.contains('linux')) return '"Linux"';
    return '"Windows"';
  }
  
  int get sessionBoundSeed => canvasNoiseSalt.hashCode ^ SessionSeed.getSessionSeed();
  
  Map<String, dynamic> toJson() {
    return {
      'userAgent': userAgent,
      'platform': platform,
      'vendor': vendor,
      'language': language,
      'hardwareConcurrency': hardwareConcurrency,
      'deviceMemory': deviceMemory,
      'deviceClass': deviceClass,
      'os': os,
      'browserEngine': browserEngine,
      'gpuFamily': gpuFamily,
      'cpu': cpu,
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
      deviceClass: json['deviceClass'] as String? ?? 'phone',
      os: json['os'] as String? ?? 'Android 14',
      browserEngine: json['browserEngine'] as String? ?? 'blink',
      gpuFamily: json['gpuFamily'] as String? ?? 'Mali',
      cpu: json['cpu'] as String? ?? 'Octa-core',
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
      deviceClass: deviceClass,
      os: os,
      browserEngine: browserEngine,
      gpuFamily: gpuFamily,
      cpu: cpu,
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
  
  bool get isMobile => deviceClass != 'pc';
  bool get isDesktop => !isMobile;

  factory FingerprintConfig.fromIdentity(MasterIdentity identity) {
    return FingerprintConfig(
      userAgent: identity.engine.userAgent,
      platform: identity.platform.os == 'Android' ? 'Linux armv8l' : 'Win32',
      vendor: 'Google Inc.', 
      language: identity.geography.locale,
      hardwareConcurrency: identity.hardware.hardwareConcurrency,
      deviceMemory: identity.hardware.deviceMemory,
      deviceClass: identity.platform.deviceClass,
      os: identity.platform.os,
      browserEngine: identity.engine.name,
      gpuFamily: identity.hardware.gpu.renderer,
      cpu: identity.hardware.cpu.model,
      maxTouchPoints: identity.platform.isMobile ? 5 : 0,
      devicePixelRatio: identity.platform.screen.pixelRatio,
      screenResolution: ScreenResolution(
        width: identity.platform.screen.width,
        height: identity.platform.screen.height,
        colorDepth: identity.platform.screen.colorDepth,
      ),
      timezone: identity.geography.timezone,
      webglConfig: WebGLConfig(
        vendor: identity.hardware.gpu.vendor,
        renderer: identity.hardware.gpu.renderer,
      ),
      canvasNoiseSalt: _generateRandomSalt(),
      webrtcEnabled: false,
    );
  }

  static String _generateRandomSalt() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String generateNewSalt() => _generateRandomSalt();

  MasterIdentity toMasterIdentity() {
    final seedStr = SessionSeed.getSessionSeed().toRadixString(16);
    
    return MasterIdentity(
      id: 'derived_\${userAgent.hashCode}',
      metadata: IdentityMetadata(label: 'Derived Profile', tier: 'mid'),
      engine: EngineConstraints(
        name: 'Blink',
        chromiumVersion: '124.0.6367.82',
        v8Version: '12.4.254.15',
        userAgent: userAgent,
      ),
      platform: PlatformIdentity(
        os: os,
        osVersion: '14',
        architecture: isMobile ? 'arm64' : 'x86_64',
        deviceClass: deviceClass,
        isMobile: isMobile,
        screen: ScreenIdentity(
          width: screenResolution.width,
          height: screenResolution.height,
          pixelRatio: devicePixelRatio,
        ),
      ),
      hardware: HardwareIdentity(
        cpu: CpuIdentity(model: cpu, architecture: isMobile ? 'arm' : 'x86'),
        gpu: GpuIdentity(
          vendor: webglConfig.vendor,
          renderer: webglConfig.renderer,
          extensions: [], 
          limits: {},
        ),
        deviceMemory: deviceMemory,
        hardwareConcurrency: hardwareConcurrency,
      ),
      geography: GeographyIdentity(
        timezone: timezone,
        locale: language,
        languages: [language, 'en'],
      ),
      sessionSeed: seedStr,
    );
  }
}

