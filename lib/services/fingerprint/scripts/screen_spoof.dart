import 'package:sec_tunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Screen Object Spoofing.
/// Normalizes screen.colorDepth/pixelDepth to 24, and ensures
/// screen.availLeft/availTop match desktop taskbar offsets (M-1 audit fix).
class ScreenSpoof {
  static String generate(FingerprintConfig config) {
    // Phase 24 Hardening: Apply to all profiles (Mobile + Desktop)
    // to prevent leakage of the real Android device screen dimensions.


    final platform = config.platform.toLowerCase();

    final width  = config.screenResolution.width;
    final height = config.screenResolution.height;
    // Desktop taskbar: Windows 40px, Mac 25px, Linux 28px (deterministic from platform)
    final isWindows = platform.contains('win');
    final isMac = platform.contains('mac');
    final taskbarH  = isWindows ? 40 : (isMac ? 25 : 28);
    final availLeft = 0;
    final availTop  = 0;

    return '''
// ===== SCREEN OBJECT SPOOFING =====
// Chrome Desktop: colorDepth=24, pixelDepth=24, availLeft/Top=0 or taskbar offset
(() => {
  try {
    const _defineScreenProp = (prop, value) => {
      try {
        Object.defineProperty(Screen.prototype, prop, {
          get: function() { return value; },
          configurable: true, enumerable: true
        });
      } catch(e) {
        try {
          Object.defineProperty(screen, prop, {
            get: function() { return value; },
            configurable: true, enumerable: true
          });
        } catch(e2) {}
      }
    };

    // M-1: Color/pixel depth — Android reports 24 but some devices report 32
    // Chrome Desktop on any OS always reports 24
    _defineScreenProp('colorDepth',  24);
    _defineScreenProp('pixelDepth',  24);

    // availLeft/Top — offset for OS taskbar/dock, 0 on most Desktop configs
    _defineScreenProp('availLeft', $availLeft);
    _defineScreenProp('availTop',  $availTop);

    // availHeight = screen height minus taskbar (desktop behavior)
    _defineScreenProp('availWidth',  $width);
    _defineScreenProp('availHeight', ${height - taskbarH});

    // screen.width / height — match config resolution
    _defineScreenProp('width',  $width);
    _defineScreenProp('height', $height);

    // orientation — Desktop Chrome reports landscape-primary for wide screens
    if (window.screen && window.screen.orientation) {
      try {
        Object.defineProperty(screen.orientation, 'type', {
          get: () => 'landscape-primary', configurable: true, enumerable: true
        });
        Object.defineProperty(screen.orientation, 'angle', {
          get: () => 0, configurable: true, enumerable: true
        });
      } catch(e) {}
    }

    // --- devicePixelRatio Spoofing ---
    // Uses the value from FingerprintConfig for cross-parameter consistency.
    // Desktop: 1, 1.25, 1.5, 2 (Mac Retina). Mobile profiles skip this block.
    const _dpr = ${config.devicePixelRatio};
    
    try {
        const spoofedDpr = function() { return _dpr; };
        self.__pbrowser_cloak(spoofedDpr, 'function get devicePixelRatio() { [native code] }');
        Object.defineProperty(window, 'devicePixelRatio', {
            get: spoofedDpr,
            configurable: true,
            enumerable: true
        });
    } catch(e) {}

  } catch(e) {}
})();
''';
  }
}
