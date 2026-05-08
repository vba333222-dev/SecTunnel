import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sec_tunnel/models/identity/master_identity.dart';
import 'device_blueprints.dart';

class IdentityFactory {
  /// Generates a stable, deterministic identity from real commercial clusters.
  static MasterIdentity generate({
    required String family,
    required String model,
    required String region,
    required String seed,
    String chromiumVersion = '124.0.6367.201',
    String v8Version = '12.4.254.20',
  }) {
    // 1. Resolve Blueprint
    final familyList = DeviceBlueprints.families[family];
    if (familyList == null) throw Exception("Unknown Device Family: $family");
    
    final blueprint = familyList.firstWhere(
      (b) => b.model == model,
      orElse: () => familyList.first,
    );

    // 2. Deterministic UUID based on inputs
    final stableId = _generateStableId(family, model, region, seed);

    // 3. Region Mapping
    final geography = _resolveGeography(region);

    // 4. Stable Viewport Drift & Version Selection (Deterministic based on seed)
    final random = Random(seed.hashCode);
    
    // Deterministic Chrome Version selection from range
    final chromeVersionInt = blueprint.minChrome + (random.nextInt(blueprint.maxChrome - blueprint.minChrome + 1));
    final selectedChromiumVersion = "$chromeVersionInt.0.${random.nextInt(1000)}.${random.nextInt(300)}";

    final viewportOffset = random.nextInt(5);
    final stableScreen = blueprint.screen.copyWith(
      height: blueprint.screen.height - viewportOffset,
    );

    // 5. Construct Identity
    return MasterIdentity(
      id: stableId,
      sessionSeed: seed,
      metadata: IdentityMetadata(
        label: "${blueprint.brand} ${blueprint.model} ($region)",
        tier: blueprint.ram >= 12 ? 'high' : (blueprint.ram >= 8 ? 'mid' : 'entry'),
      ),
      engine: EngineConstraints(
        name: 'Blink',
        chromiumVersion: selectedChromiumVersion,
        v8Version: v8Version,
        userAgent: blueprint.userAgentTemplate.replaceAll('{version}', selectedChromiumVersion),
      ),
      platform: PlatformIdentity(
        os: blueprint.os,
        osVersion: blueprint.osVersion,
        architecture: blueprint.architecture,
        deviceClass: blueprint.deviceClass,
        isMobile: blueprint.isMobile,
        screen: stableScreen,
        maxTouchPoints: blueprint.touchPoints,
      ),
      hardware: HardwareIdentity(
        cpu: blueprint.cpu,
        gpu: blueprint.gpu,
        deviceMemory: blueprint.ram,
        hardwareConcurrency: blueprint.cores,
      ),
      geography: geography,
    );
  }

  static String _generateStableId(String family, String model, String region, String seed) {
    final bytes = utf8.encode("$family:$model:$region:$seed");
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  static GeographyIdentity _resolveGeography(String region) {
    switch (region.toUpperCase()) {
      case 'ID':
        return GeographyIdentity(
          timezone: 'Asia/Jakarta', // Default to WIB, WITA/WIT can be dynamic later
          locale: 'id-ID',
          languages: ['id-ID', 'id', 'en-US', 'en'], // Realistic ID mobile weighting
          ipRegion: 'ID',
        );
      case 'US':
        return GeographyIdentity(
          timezone: 'America/New_York',
          locale: 'en-US',
          languages: ['en-US', 'en'],
          ipRegion: 'US',
        );
      case 'UK':
        return GeographyIdentity(
          timezone: 'Europe/London',
          locale: 'en-GB',
          languages: ['en-GB', 'en'],
          ipRegion: 'GB',
        );
      default:
        return GeographyIdentity(
          timezone: 'UTC',
          locale: 'en-US',
          languages: ['en-US', 'en'],
        );
    }
  }
}
