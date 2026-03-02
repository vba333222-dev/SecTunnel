import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Window Frame Metrics Spoofing.
/// Ensures outerWidth > innerWidth (by a small desktop-realistic frame offset),
/// preventing detection via inner/outer dimension equality checks.
class WindowMetricsSpoof {
  static String generate(FingerprintConfig config) {
    final width = config.screenResolution.width;
    final height = config.screenResolution.height;
    // Deterministic "frame border size" seeded from profile, 15–20px range
    final seed = config.canvasNoiseSalt.hashCode.abs();
    final scrollbarW = 15 + (seed % 6);       // 15–20 px
    final chromeH = 95 + ((seed >> 4) % 20);  // 95–114 px (tab bar + address bar)

    return '''
// ===== WINDOW FRAME METRICS SPOOFING =====
// Desktop Chrome: outerWidth = innerWidth + scrollbar
//                 outerHeight = innerHeight + chrome UI (tabs, address bar)
(() => {
  try {
    // --- Deterministic values derived from profile seed ---
    const INNER_W  = $width;
    const INNER_H  = ${height - chromeH};
    const OUTER_W  = $width  + $scrollbarW;
    const OUTER_H  = $height;

    const defineWindowProp = (prop, value) => {
      const getter = function() { return value; };
      window.__pbrowser_cloak(getter, 'function get ' + prop + '() { [native code] }');
      try {
        Object.defineProperty(window, prop, {
          get: getter,
          set: undefined,
          enumerable: true,
          configurable: true
        });
      } catch(e) {
        // Fallback for non-configurable — use direct assignment if window allows it
        try { window[prop] = value; } catch(e2) {}
      }
    };

    defineWindowProp('innerWidth',  INNER_W);
    defineWindowProp('innerHeight', INNER_H);
    defineWindowProp('outerWidth',  OUTER_W);
    defineWindowProp('outerHeight', OUTER_H);

    // Also spoof devicePixelRatio to a standard desktop value (1 or 2)
    // WebViews often report 2.75, 3.0 etc — distinctly mobile device DPRs
    const dpr = ${ (seed % 2) == 0 ? 1 : 2 };
    defineWindowProp('devicePixelRatio', dpr);

  } catch(e) {}
})();
''';
  }
}
