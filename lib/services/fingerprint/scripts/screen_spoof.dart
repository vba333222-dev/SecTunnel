import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Screen Object Spoofing.
/// Normalizes screen.colorDepth/pixelDepth to 24, and ensures
/// screen.availLeft/availTop match desktop taskbar offsets (M-1 audit fix).
class ScreenSpoof {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win') ||
        platform.contains('mac') ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    if (!isDesktop) {
      return '// [ScreenSpoof] Mobile profile — screen properties intact.';
    }

    final seed = config.canvasNoiseSalt.hashCode.abs();
    final width  = config.screenResolution.width;
    final height = config.screenResolution.height;
    // Desktop taskbar typically 40–48px on Windows, 25px on Mac
    final isWindows = platform.contains('win');
    final taskbarH  = isWindows ? 40 + (seed % 8) : 25;
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

  } catch(e) {}
})();
''';
  }
}
