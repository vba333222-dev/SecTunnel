import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Network Information API Spoofing.
/// Strips mobile-exclusive properties (.type, .saveData) from navigator.connection
/// on Desktop profiles to match Chrome Desktop NetworkInformation structure.
class NetworkInfoSpoof {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win') ||
        platform.contains('mac') ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    if (!isDesktop) {
      return '// [NetworkInfoSpoof] Mobile profile — NetworkInformation intact.';
    }

    // Desktop-realistic downlink: 8–95 Mbps range, seeded per profile
    final seed     = config.canvasNoiseSalt.hashCode.abs();
    final downlink = 8.0 + (seed % 87);     // 8–95 Mbps
    final rtt      = 10 + (seed % 40);      // 10–49 ms

    return '''
// ===== NETWORK INFORMATION API SPOOFING =====
// Chrome Desktop exposes: effectiveType, downlink, rtt, onchange
// Chrome Desktop does NOT expose: type, saveData (mobile-only)
(() => {
  try {
    if (!navigator.connection) return;

    const conn     = navigator.connection;
    const connProto = Object.getPrototypeOf(conn);

    // Properties that exist on Chrome Android/WebView but NOT on Chrome Desktop
    const MOBILE_ONLY_PROPS = ['type', 'saveData'];

    // Desktop-realistic network values (seeded per profile)
    const DESKTOP_DOWNLINK      = ${downlink.toStringAsFixed(1)};
    const DESKTOP_RTT           = $rtt;
    const DESKTOP_DOWNLINK_MAX  = ${(downlink * 1.1 + 5).toStringAsFixed(1)};

    // Properties to normalize to desktop-typical values (H-3 fix)
    const NORMALIZE_PROPS = {
      effectiveType: '4g',
      downlink:      DESKTOP_DOWNLINK,
      downlinkMax:   DESKTOP_DOWNLINK_MAX,
      rtt:           DESKTOP_RTT,
    };

    // Build a Proxy that intercepts property access
    const spoofedConnection = new Proxy(conn, {
      get(target, prop, receiver) {
        // Block mobile-only properties
        if (MOBILE_ONLY_PROPS.includes(prop)) return undefined;
        // Normalize desktop-specific values
        if (Object.prototype.hasOwnProperty.call(NORMALIZE_PROPS, prop)) {
          return NORMALIZE_PROPS[prop];
        }
        const val = Reflect.get(target, prop, receiver);
        return typeof val === 'function' ? val.bind(target) : val;
      },
      has(target, prop) {
        if (MOBILE_ONLY_PROPS.includes(prop)) return false;
        return Reflect.has(target, prop);
      },
      getOwnPropertyDescriptor(target, prop) {
        if (MOBILE_ONLY_PROPS.includes(prop)) return undefined;
        return Reflect.getOwnPropertyDescriptor(target, prop);
      },
      ownKeys(target) {
        return Reflect.ownKeys(target).filter(k => !MOBILE_ONLY_PROPS.includes(String(k)));
      }
    });

    // Override navigator.connection getter to return our Proxy
    const connectionGetter = function() { return spoofedConnection; };
    window.__pbrowser_cloak(connectionGetter, 'function get connection() { [native code] }');

    // Try to override on NetworkInformation prototype first (cleaner)
    try {
      const ni = typeof NetworkInformation !== 'undefined'
        ? NetworkInformation.prototype
        : connProto;

      // Can't redefine on prototype easily; target Navigator.prototype instead
      Object.defineProperty(Navigator.prototype, 'connection', {
        get: connectionGetter,
        set: undefined,
        enumerable: true,
        configurable: true
      });
    } catch(e) {
      // Fallback: redefine on the navigator instance directly
      Object.defineProperty(navigator, 'connection', {
        get: connectionGetter,
        set: undefined,
        enumerable: true,
        configurable: true
      });
    }

    // Also expose the standardised alias .mozConnection / .webkitConnection
    // (some older fingerprint scripts check these aliases)
    ['mozConnection', 'webkitConnection'].forEach(alias => {
      try {
        if (!(alias in navigator)) return;
        Object.defineProperty(Navigator.prototype, alias, {
          get: connectionGetter,
          set: undefined,
          enumerable: true,
          configurable: true
        });
      } catch(e) {}
    });

  } catch(e) {}
})();
''';
  }
}
