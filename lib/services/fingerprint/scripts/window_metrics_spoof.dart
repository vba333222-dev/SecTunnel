import 'package:sec_tunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Window Frame Metrics Spoofing.
/// Ensures outerWidth > innerWidth (by a small desktop-realistic frame offset),
/// preventing detection via inner/outer dimension equality checks.
/// 
/// All values derive from FingerprintConfig — no independent generation.
class WindowMetricsSpoof {
  static String generate(FingerprintConfig config) {
    final width = config.screenResolution.width;
    final height = config.screenResolution.height;
    final platform = config.platform.toLowerCase();
    
    // Deterministic frame metrics from config platform (not from seed)
    // Windows: 17px scrollbar, 95px chrome. Mac: 15px, 88px. Linux: 15px, 90px.
    final int scrollbarW;
    final int chromeH;
    if (platform.contains('win')) {
      scrollbarW = 17;
      chromeH = 95;
    } else if (platform.contains('mac')) {
      scrollbarW = 15;
      chromeH = 88;
    } else {
      scrollbarW = 15;
      chromeH = 90;
    }

    return '''
// ===== WINDOW FRAME METRICS SPOOFING =====
// Desktop Chrome: outerWidth = innerWidth + scrollbar
//                 outerHeight = innerHeight + chrome UI (tabs, address bar)
(() => {
  try {
    // --- Values from FingerprintConfig (no seed derivation) ---
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

    // DPR is handled by screen_spoof.dart from config.devicePixelRatio.
    // Removed duplicate DPR override here (was seed-based, inconsistent).

  } catch(e) {}
})();
''';
  }
}
