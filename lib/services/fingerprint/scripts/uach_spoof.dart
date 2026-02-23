import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for User-Agent Client Hints (UA-CH) Spoofing.
/// Creates a complete NavigatorUAData mock aligned with the active FingerprintConfig,
/// covering both low-entropy (brands, mobile, platform) and high-entropy getHighEntropyValues().
class UACHSpoof {
  static String generate(FingerprintConfig config) {
    // Derive platform metadata from the active profile config
    final ua = config.userAgent;
    final platform = config.platform;

    // Determine OS, architecture, and Chrome version from UA
    final lowerCasePlatform = config.platform.toLowerCase();
    final isWindows = lowerCasePlatform.contains('win');
    final isMac     = lowerCasePlatform.contains('mac');  // covers 'macintel', 'mac arm', etc.
    final isLinux   = lowerCasePlatform.contains('linux');
    final isMobile  = !isWindows && !isMac && !isLinux;

    // Extract Chrome major version from userAgent string
    // e.g. "Chrome/120.0.0.0" → 120
    final chromeMajor = _extractChromeMajor(ua);
    final chromeFullVersion = '$chromeMajor.0.0.0';

    // OS-specific metadata
    final (platformStr, arch, bitness, platformVer) = _platformMetadata(platform);

    final brandsJson = '''[
        { "brand": "Google Chrome",          "version": "$chromeMajor" },
        { "brand": "Chromium",               "version": "$chromeMajor" },
        { "brand": "Not_A Brand",            "version": "8"  }
      ]''';

    final fullBrandsJson = '''[
        { "brand": "Google Chrome",          "version": "$chromeFullVersion" },
        { "brand": "Chromium",               "version": "$chromeFullVersion" },
        { "brand": "Not_A Brand",            "version": "8.0.0.0" }
      ]''';

    return '''
// ===== USER-AGENT CLIENT HINTS (UA-CH) SPOOFING =====
(() => {
  try {
    // Prevent double-injection
    if (navigator.__pbrowser_uach_injected) return;

    // ---- Build the complete NavigatorUAData mock ----

    const brands      = $brandsJson;
    const fullBrands  = $fullBrandsJson;
    const isMobile    = $isMobile;
    const platform    = '$platformStr';
    const arch        = '$arch';
    const bitness     = '$bitness';
    const platformVer = '$platformVer';
    const model       = '';
    const uaFullVer   = '$chromeFullVersion';

    // High-entropy values map — returned ONLY for requested hints
    const HIGH_ENTROPY_MAP = {
      brands:                 brands,
      fullVersionList:        fullBrands,
      mobile:                 isMobile,
      platform:               platform,
      platformVersion:        platformVer,
      architecture:           arch,
      bitness:                bitness,
      model:                  model,
      uaFullVersion:          uaFullVer,
      wow64:                  false,
    };

    // getHighEntropyValues returns a Promise resolving to
    // an object containing exactly the requested keys
    const spoofedGetHighEntropyValues = function(hints) {
      const result = {};
      if (Array.isArray(hints)) {
        hints.forEach(hint => {
          if (hint in HIGH_ENTROPY_MAP) {
            result[hint] = HIGH_ENTROPY_MAP[hint];
          }
        });
      }
      return Promise.resolve(result);
    };
    window.__pbrowser_cloak(spoofedGetHighEntropyValues,
      'function getHighEntropyValues() { [native code] }');

    // toJSON serializes the low-entropy surface
    const spoofedToJSON = function() {
      return { brands, mobile: isMobile, platform };
    };
    window.__pbrowser_cloak(spoofedToJSON, 'function toJSON() { [native code] }');

    // Build the NavigatorUAData mock object
    const mockUAData = Object.create(
      typeof NavigatorUAData !== 'undefined' ? NavigatorUAData.prototype : Object.prototype
    );

    Object.defineProperty(mockUAData, 'brands',   { get: () => brands,   enumerable: true, configurable: true });
    Object.defineProperty(mockUAData, 'mobile',   { get: () => isMobile, enumerable: true, configurable: true });
    Object.defineProperty(mockUAData, 'platform', { get: () => platform, enumerable: true, configurable: true });
    mockUAData.getHighEntropyValues = spoofedGetHighEntropyValues;
    mockUAData.toJSON               = spoofedToJSON;

    // ---- Inject into Navigator.prototype ----
    const uaDataGetter = function() { return mockUAData; };
    window.__pbrowser_cloak(uaDataGetter, 'function get userAgentData() { [native code] }');

    Object.defineProperty(Navigator.prototype, 'userAgentData', {
      get: uaDataGetter,
      set: undefined,
      enumerable: true,
      configurable: true
    });

    // Mark as injected to prevent double-run
    Object.defineProperty(navigator, '__pbrowser_uach_injected', {
      value: true, writable: false, enumerable: false, configurable: false
    });

  } catch(e) {}
})();
''';
  }

  static int _extractChromeMajor(String ua) {
    final regex = RegExp(r'Chrome/(\d+)');
    final match = regex.firstMatch(ua);
    if (match != null) return int.tryParse(match.group(1) ?? '120') ?? 120;
    return 120;
  }

  static (String platform, String arch, String bitness, String version) _platformMetadata(
      String platform) {
    final p = platform.toLowerCase();
    if (p.contains('win')) {
      return ('Windows', 'x86', '64', '15.0.0'); // Windows 11
    } else if (p.contains('mac')) {
      return ('macOS', 'arm', '64', '14.4.1');   // macOS Sonoma
    } else {
      return ('Linux', 'x86', '64', '6.5.0');    // Linux 6.5
    }
  }
}
