// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasterIdentity _$MasterIdentityFromJson(Map<String, dynamic> json) =>
    MasterIdentity(
      id: json['id'] as String,
      metadata:
          IdentityMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      engine:
          EngineConstraints.fromJson(json['engine'] as Map<String, dynamic>),
      platform:
          PlatformIdentity.fromJson(json['platform'] as Map<String, dynamic>),
      hardware:
          HardwareIdentity.fromJson(json['hardware'] as Map<String, dynamic>),
      geography:
          GeographyIdentity.fromJson(json['geography'] as Map<String, dynamic>),
      sessionSeed: json['sessionSeed'] as String,
    );

Map<String, dynamic> _$MasterIdentityToJson(MasterIdentity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metadata': instance.metadata,
      'engine': instance.engine,
      'platform': instance.platform,
      'hardware': instance.hardware,
      'geography': instance.geography,
      'sessionSeed': instance.sessionSeed,
    };

IdentityMetadata _$IdentityMetadataFromJson(Map<String, dynamic> json) =>
    IdentityMetadata(
      label: json['label'] as String,
      tier: json['tier'] as String,
    );

Map<String, dynamic> _$IdentityMetadataToJson(IdentityMetadata instance) =>
    <String, dynamic>{
      'label': instance.label,
      'tier': instance.tier,
    };

EngineConstraints _$EngineConstraintsFromJson(Map<String, dynamic> json) =>
    EngineConstraints(
      name: json['name'] as String,
      chromiumVersion: json['chromiumVersion'] as String,
      v8Version: json['v8Version'] as String,
      userAgent: json['userAgent'] as String,
    );

Map<String, dynamic> _$EngineConstraintsToJson(EngineConstraints instance) =>
    <String, dynamic>{
      'name': instance.name,
      'chromiumVersion': instance.chromiumVersion,
      'v8Version': instance.v8Version,
      'userAgent': instance.userAgent,
    };

PlatformIdentity _$PlatformIdentityFromJson(Map<String, dynamic> json) =>
    PlatformIdentity(
      os: json['os'] as String,
      osVersion: json['osVersion'] as String,
      architecture: json['architecture'] as String,
      deviceClass: json['deviceClass'] as String,
      isMobile: json['isMobile'] as bool,
      screen: ScreenIdentity.fromJson(json['screen'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlatformIdentityToJson(PlatformIdentity instance) =>
    <String, dynamic>{
      'os': instance.os,
      'osVersion': instance.osVersion,
      'architecture': instance.architecture,
      'deviceClass': instance.deviceClass,
      'isMobile': instance.isMobile,
      'screen': instance.screen,
    };

ScreenIdentity _$ScreenIdentityFromJson(Map<String, dynamic> json) =>
    ScreenIdentity(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      pixelRatio: (json['pixelRatio'] as num).toDouble(),
      colorDepth: (json['colorDepth'] as num?)?.toInt() ?? 24,
    );

Map<String, dynamic> _$ScreenIdentityToJson(ScreenIdentity instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'pixelRatio': instance.pixelRatio,
      'colorDepth': instance.colorDepth,
    };

HardwareIdentity _$HardwareIdentityFromJson(Map<String, dynamic> json) =>
    HardwareIdentity(
      cpu: CpuIdentity.fromJson(json['cpu'] as Map<String, dynamic>),
      gpu: GpuIdentity.fromJson(json['gpu'] as Map<String, dynamic>),
      deviceMemory: (json['deviceMemory'] as num).toInt(),
      hardwareConcurrency: (json['hardwareConcurrency'] as num).toInt(),
    );

Map<String, dynamic> _$HardwareIdentityToJson(HardwareIdentity instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'gpu': instance.gpu,
      'deviceMemory': instance.deviceMemory,
      'hardwareConcurrency': instance.hardwareConcurrency,
    };

CpuIdentity _$CpuIdentityFromJson(Map<String, dynamic> json) => CpuIdentity(
      model: json['model'] as String,
      architecture: json['architecture'] as String,
    );

Map<String, dynamic> _$CpuIdentityToJson(CpuIdentity instance) =>
    <String, dynamic>{
      'model': instance.model,
      'architecture': instance.architecture,
    };

GpuIdentity _$GpuIdentityFromJson(Map<String, dynamic> json) => GpuIdentity(
      vendor: json['vendor'] as String,
      renderer: json['renderer'] as String,
      extensions: (json['extensions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      limits: json['limits'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$GpuIdentityToJson(GpuIdentity instance) =>
    <String, dynamic>{
      'vendor': instance.vendor,
      'renderer': instance.renderer,
      'extensions': instance.extensions,
      'limits': instance.limits,
    };

GeographyIdentity _$GeographyIdentityFromJson(Map<String, dynamic> json) =>
    GeographyIdentity(
      timezone: json['timezone'] as String,
      locale: json['locale'] as String,
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      ipRegion: json['ipRegion'] as String? ?? 'US',
    );

Map<String, dynamic> _$GeographyIdentityToJson(GeographyIdentity instance) =>
    <String, dynamic>{
      'timezone': instance.timezone,
      'locale': instance.locale,
      'languages': instance.languages,
      'ipRegion': instance.ipRegion,
    };
