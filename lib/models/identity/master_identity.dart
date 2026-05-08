import 'package:json_annotation/json_annotation.dart';

part 'master_identity.g.dart';

@JsonSerializable()
class MasterIdentity {
  final String id;
  final IdentityMetadata metadata;
  final EngineConstraints engine;
  final PlatformIdentity platform;
  final HardwareIdentity hardware;
  final GeographyIdentity geography;
  final String sessionSeed;

  const MasterIdentity({
    required this.id,
    required this.metadata,
    required this.engine,
    required this.platform,
    required this.hardware,
    required this.geography,
    required this.sessionSeed,
  });

  factory MasterIdentity.fromJson(Map<String, dynamic> json) => _$MasterIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$MasterIdentityToJson(this);
}

@JsonSerializable()
class IdentityMetadata {
  final String label;
  final String tier; // 'entry', 'mid', 'high'

  const IdentityMetadata({required this.label, required this.tier});

  factory IdentityMetadata.fromJson(Map<String, dynamic> json) => _$IdentityMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$IdentityMetadataToJson(this);
}

@JsonSerializable()
class EngineConstraints {
  final String name; // Always 'Blink'
  final String chromiumVersion;
  final String v8Version;
  final String userAgent;

  const EngineConstraints({
    required this.name,
    required this.chromiumVersion,
    required this.v8Version,
    required this.userAgent,
  });

  factory EngineConstraints.fromJson(Map<String, dynamic> json) => _$EngineConstraintsFromJson(json);
  Map<String, dynamic> toJson() => _$EngineConstraintsToJson(this);
}

@JsonSerializable()
class PlatformIdentity {
  final String os; // 'Android', 'Windows', 'Linux'
  final String osVersion;
  final String architecture; // 'arm64', 'x86_64'
  final String deviceClass; // 'mobile', 'desktop', 'tablet'
  final bool isMobile;
  final ScreenIdentity screen;
  final int maxTouchPoints;

  const PlatformIdentity({
    required this.os,
    required this.osVersion,
    required this.architecture,
    required this.deviceClass,
    required this.isMobile,
    required this.screen,
    this.maxTouchPoints = 5,
  });

  factory PlatformIdentity.fromJson(Map<String, dynamic> json) => _$PlatformIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformIdentityToJson(this);
}

@JsonSerializable()
class ScreenIdentity {
  final int width;
  final int height;
  final double pixelRatio;
  final int colorDepth;

  const ScreenIdentity({
    required this.width,
    required this.height,
    required this.pixelRatio,
    this.colorDepth = 24,
  });

  ScreenIdentity copyWith({
    int? width,
    int? height,
    double? pixelRatio,
    int? colorDepth,
  }) {
    return ScreenIdentity(
      width: width ?? this.width,
      height: height ?? this.height,
      pixelRatio: pixelRatio ?? this.pixelRatio,
      colorDepth: colorDepth ?? this.colorDepth,
    );
  }

  factory ScreenIdentity.fromJson(Map<String, dynamic> json) => _$ScreenIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$ScreenIdentityToJson(this);
}

@JsonSerializable()
class HardwareIdentity {
  final CpuIdentity cpu;
  final GpuIdentity gpu;
  final int deviceMemory; // in GB
  final int hardwareConcurrency;

  const HardwareIdentity({
    required this.cpu,
    required this.gpu,
    required this.deviceMemory,
    required this.hardwareConcurrency,
  });

  factory HardwareIdentity.fromJson(Map<String, dynamic> json) => _$HardwareIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$HardwareIdentityToJson(this);
}

@JsonSerializable()
class CpuIdentity {
  final String model;
  final String architecture;

  const CpuIdentity({required this.model, required this.architecture});

  factory CpuIdentity.fromJson(Map<String, dynamic> json) => _$CpuIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$CpuIdentityToJson(this);
}

@JsonSerializable()
class GpuIdentity {
  final String vendor;
  final String renderer;
  final List<String> extensions;
  final Map<String, dynamic> limits;

  const GpuIdentity({
    required this.vendor,
    required this.renderer,
    required this.extensions,
    required this.limits,
  });

  factory GpuIdentity.fromJson(Map<String, dynamic> json) => _$GpuIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$GpuIdentityToJson(this);
}

@JsonSerializable()
class GeographyIdentity {
  final String timezone;
  final String locale;
  final List<String> languages;
  final String ipRegion;

  const GeographyIdentity({
    required this.timezone,
    required this.locale,
    required this.languages,
    this.ipRegion = 'US',
  });

  factory GeographyIdentity.fromJson(Map<String, dynamic> json) => _$GeographyIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$GeographyIdentityToJson(this);
}
