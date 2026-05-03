import 'package:sec_tunnel/models/fingerprint_config.dart';

/// Cross-validates all fingerprint parameters for internal consistency.
/// Catches mismatches that anti-detect scanners look for:
/// - platform vs userAgent mismatch
/// - mobile UA with desktop screen resolution
/// - DPR inconsistent with device class
/// - WebGL vendor mismatch with platform
class FingerprintValidator {
  /// Returns a list of inconsistency warnings (empty = valid).
  static List<String> validate(FingerprintConfig config) {
    final warnings = <String>[];
    final ua = config.userAgent.toLowerCase();
    final platform = config.platform.toLowerCase();
    final isMobileUA =
        ua.contains('mobile') || ua.contains('iphone') || ua.contains('android');
    final isDesktopPlatform =
        platform.contains('win') ||
        platform == 'macintel' ||
        platform.contains('linux x86') ||
        platform.contains('linux x64');

    // ── 1. Platform ↔ UserAgent coherence ───────────────────
    if (isMobileUA && isDesktopPlatform) {
      warnings.add('Mobile UA with desktop platform ($platform)');
    }
    if (!isMobileUA && !isDesktopPlatform) {
      warnings.add('Desktop UA with mobile platform ($platform)');
    }

    // ── 2. Vendor ↔ UA coherence ────────────────────────────
    if (ua.contains('iphone') || ua.contains('ipad')) {
      if (config.vendor != 'Apple Computer, Inc.') {
        warnings.add('iOS UA requires vendor "Apple Computer, Inc."');
      }
    }

    // ── 3. Screen resolution ↔ device class ─────────────────
    final w = config.screenResolution.width;
    if (isMobileUA && w > 1024) {
      warnings.add('Mobile UA with desktop-class resolution (${w}px width)');
    }
    if (!isMobileUA && w < 800) {
      warnings.add('Desktop UA with mobile-class resolution (${w}px width)');
    }

    // ── 4. DPR ↔ device class ───────────────────────────────
    if (isMobileUA && config.devicePixelRatio < 1.5) {
      warnings.add('Mobile UA with low DPR (${config.devicePixelRatio})');
    }
    if (!isMobileUA && config.devicePixelRatio > 2.0) {
      warnings.add('Desktop UA with high DPR (${config.devicePixelRatio})');
    }

    // ── 5. maxTouchPoints ↔ device class ────────────────────
    if (isMobileUA && config.maxTouchPoints == 0) {
      warnings.add('Mobile UA with zero touch points');
    }
    if (!isMobileUA && config.maxTouchPoints > 1) {
      warnings.add('Desktop UA with mobile touch points (${config.maxTouchPoints})');
    }

    // ── 6. Hardware ↔ device class ──────────────────────────
    if (isMobileUA && config.hardwareConcurrency > 16) {
      warnings.add('Mobile UA with unrealistic CPU cores (${config.hardwareConcurrency})');
    }
    if (isMobileUA && config.deviceMemory > 16) {
      warnings.add('Mobile UA with unrealistic RAM (${config.deviceMemory}GB)');
    }

    // ── 7. WebGL ↔ platform ─────────────────────────────────
    final renderer = config.webglConfig.renderer.toLowerCase();
    if (platform.contains('win') && renderer.contains('apple gpu')) {
      warnings.add('Windows platform with Apple GPU renderer');
    }
    if ((platform == 'iphone' || platform == 'macintel') &&
        renderer.contains('adreno')) {
      warnings.add('Apple platform with Adreno GPU renderer');
    }

    return warnings;
  }

  /// Returns true if the config is consistent enough for production use.
  static bool isValid(FingerprintConfig config) => validate(config).isEmpty;

  /// Validates config and throws [FingerprintInconsistencyException]
  /// if any cross-parameter mismatches are detected.
  /// Used by FingerprintInjector to hard-block injection of broken profiles.
  static void assertValid(FingerprintConfig config) {
    final warnings = validate(config);
    if (warnings.isNotEmpty) {
      throw FingerprintInconsistencyException(warnings);
    }
  }
}

/// Thrown when FingerprintConfig contains cross-parameter inconsistencies
/// that would be detectable by anti-fingerprint scanners.
class FingerprintInconsistencyException implements Exception {
  final List<String> inconsistencies;

  const FingerprintInconsistencyException(this.inconsistencies);

  @override
  String toString() =>
      'FingerprintInconsistencyException: ${inconsistencies.join('; ')}';
}
