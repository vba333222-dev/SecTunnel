import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for System-UI Font Metrics Spoofing.
/// Overrides HTMLElement offsetWidth/Height and canvas measureText to inject
/// a deterministic sub-pixel delta that masks Android Roboto font baseline kerning.
class FontMetricsSpoof {
  static String generate(FingerprintConfig config) {
    final seed = config.canvasNoiseSalt.hashCode.abs();
    // Produce two small offsets in the range of ± 1.5px —
    // enough to shift Roboto measurements away from its characteristic baseline,
    // but small enough to not break real layout calculations.
    final widthDelta  =  (seed % 30) / 10.0 - 1.5;    // -1.5 to +1.5 px
    final heightDelta = ((seed >> 4) % 20) / 10.0 - 1.0; // -1.0 to +1.0 px

    return '''
// ===== SYSTEM-UI FONT METRICS SPOOFING =====
// Masks Roboto kerning signature on offsetWidth/Height and canvas measureText.
(() => {
  try {
    // Deterministic deltas seeded from profile (consistent across page reloads)
    const WIDTH_DELTA  = $widthDelta;
    const HEIGHT_DELTA = $heightDelta;

    // Mulberry32 for measureText sub-pixel noise (position-dependent)
    let _rng = ${seed};
    const nextφ = () => {
      _rng += 0x6D2B79F5;
      let z = _rng;
      z = Math.imul(z ^ z >>> 15, z | 1);
      z ^= z + Math.imul(z ^ z >>> 7, z | 61);
      return ((z ^ z >>> 14) >>> 0) / 0xFFFFFFFF;
    };

    // =====================================================
    // 1. HTMLElement.prototype.offsetWidth
    // =====================================================
    const origOffsetWidthDesc = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'offsetWidth');
    if (origOffsetWidthDesc && origOffsetWidthDesc.get) {
      const origGet = origOffsetWidthDesc.get;
      const spoofedGet = function() {
        const real = origGet.call(this);
        if (real === 0) return 0; // Don't corrupt invisible elements
        return real + WIDTH_DELTA;
      };
      window.__pbrowser_cloak(spoofedGet, 'function get offsetWidth() { [native code] }');
      Object.defineProperty(HTMLElement.prototype, 'offsetWidth', {
        get: spoofedGet,
        set: origOffsetWidthDesc.set,
        enumerable: origOffsetWidthDesc.enumerable,
        configurable: true
      });
    }

    // =====================================================
    // 2. HTMLElement.prototype.offsetHeight
    // =====================================================
    const origOffsetHeightDesc = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'offsetHeight');
    if (origOffsetHeightDesc && origOffsetHeightDesc.get) {
      const origGet = origOffsetHeightDesc.get;
      const spoofedGet = function() {
        const real = origGet.call(this);
        if (real === 0) return 0;
        return real + HEIGHT_DELTA;
      };
      window.__pbrowser_cloak(spoofedGet, 'function get offsetHeight() { [native code] }');
      Object.defineProperty(HTMLElement.prototype, 'offsetHeight', {
        get: spoofedGet,
        set: origOffsetHeightDesc.set,
        enumerable: origOffsetHeightDesc.enumerable,
        configurable: true
      });
    }

    // =====================================================
    // 3. CanvasRenderingContext2D.prototype.measureText
    // =====================================================
    const origMeasureText = CanvasRenderingContext2D.prototype.measureText;
    const spoofedMeasureText = function(text) {
      const real = origMeasureText.call(this, text);

      // Build a proxy around the TextMetrics result that perturbs all width props
      const fuzz = (v) => typeof v === 'number' && v !== 0
        ? v + WIDTH_DELTA + (nextφ() * 0.04 - 0.02) // ±0.02 extra sub-pixel jitter
        : v;

      const metrics = Object.create(TextMetrics.prototype);
      const PROPS = [
        'width', 'actualBoundingBoxLeft', 'actualBoundingBoxRight',
        'fontBoundingBoxAscent', 'fontBoundingBoxDescent',
        'actualBoundingBoxAscent', 'actualBoundingBoxDescent',
        'emHeightAscent', 'emHeightDescent',
        'hangingBaseline', 'alphabeticBaseline', 'ideographicBaseline'
      ];
      PROPS.forEach(prop => {
        try {
          const val = real[prop];
          if (val !== undefined) {
            Object.defineProperty(metrics, prop, {
              value: fuzz(val), enumerable: true, configurable: true
            });
          }
        } catch(e) {}
      });

      return metrics;
    };
    window.__pbrowser_cloak(spoofedMeasureText, 'function measureText() { [native code] }');
    CanvasRenderingContext2D.prototype.measureText = spoofedMeasureText;

    // =====================================================
    // 4. Publish font deltas as window globals for DOMRectSpoof
    // =====================================================
    // NOTE: getBoundingClientRect is handled exclusively by domrect_spoof.dart.
    // We publish our deltas here so DOMRectSpoof can incorporate them in its
    // override, avoiding a double-override conflict (C-5 audit fix).
    window.__pbr_wdelta = WIDTH_DELTA;
    window.__pbr_hdelta = HEIGHT_DELTA;

  } catch(e) {}
})();
''';
  }
}
