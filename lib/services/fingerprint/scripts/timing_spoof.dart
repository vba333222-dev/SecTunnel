import 'package:SecTunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Performance Timing Attack Evasion.
/// Reduces resolution of performance.now() and Date.now(), and adds
/// a micro-jitter to defeat Proxy overhead timing comparison by Kasada/Cloudflare.
class TimingSpoof {
  static String generate(FingerprintConfig config) {
    // Deterministic jitter amplitude: 0.1–0.5ms range per profile
    final seed = config.canvasNoiseSalt.hashCode.abs();
    final jitterMax = 0.1 + (seed % 5) * 0.1; // 0.1 to 0.5 ms
    // Rounding granularity: 1ms or 2ms bucket
    final roundMs = (seed % 2 == 0) ? 1 : 2;

    return '''
// ===== PERFORMANCE TIMING ATTACK EVASION =====
// Reduces sub-millisecond precision of timing APIs to prevent
// Proxy-overhead timing comparisons (Kasada, PerimeterX, Cloudflare).
(() => {
  try {
    const JITTER_MAX     = $jitterMax;   // Max random jitter in ms
    const ROUND_MS       = $roundMs;     // Bucket size for rounding
    const profileSeed    = $seed;

    // Simple stateless PRNG for jitter generation (not security-critical)
    let _rngState = profileSeed | 0; // C-7 fix: force signed 32-bit from start
    const nextRand = () => {
      _rngState ^= (_rngState << 13) | 0;
      _rngState ^= (_rngState >> 17) | 0;  // arithmetic right shift, stays 32-bit
      _rngState ^= (_rngState << 5)  | 0;
      return ((_rngState >>> 0) / 0xFFFFFFFF); // unsigned division for [0,1) range
    };

    // Fuzz: round to nearest ROUND_MS bucket then add tiny jitter
    const fuzz = (t) => {
      const rounded = Math.round(t / ROUND_MS) * ROUND_MS;
      const jitter  = (nextRand() * 2 - 1) * JITTER_MAX;
      return rounded + jitter;
    };

    // =============================================
    // 1. performance.now()
    // =============================================
    const originalPerformanceNow = Performance.prototype.now;
    const spoofedPerformanceNow = function() {
      const real = originalPerformanceNow.apply(this, arguments);
      return fuzz(real);
    };
    window.__pbrowser_cloak(spoofedPerformanceNow, 'function now() { [native code] }');
    Performance.prototype.now = spoofedPerformanceNow;

    // =============================================
    // 2. Date.now()
    // =============================================
    const originalDateNow = Date.now;
    const spoofedDateNow = function() {
      const real = originalDateNow.apply(this, arguments);
      // Date.now() is integer ms — round to nearest ROUND_MS bucket + int jitter
      return Math.round(fuzz(real));
    };
    window.__pbrowser_cloak(spoofedDateNow, 'function now() { [native code] }');
    Date.now = spoofedDateNow;

    // =============================================
    // 3. new Date()  — masks precise sub-ms construction
    // =============================================
    const OriginalDate = Date;
    const SpoofedDate  = function(...args) {
      if (args.length === 0) {
        return new OriginalDate(Math.round(fuzz(OriginalDate.now())));
      }
      return new OriginalDate(...args);
    };
    // Copy all static methods and Symbol references
    Object.setPrototypeOf(SpoofedDate, OriginalDate);
    SpoofedDate.prototype = OriginalDate.prototype;
    SpoofedDate.now       = spoofedDateNow;
    SpoofedDate.UTC       = OriginalDate.UTC.bind(OriginalDate);
    SpoofedDate.parse     = OriginalDate.parse.bind(OriginalDate);
    window.__pbrowser_cloak(SpoofedDate, 'function Date() { [native code] }');
    try {
      window.Date = SpoofedDate;
    } catch(e) {}

    // =============================================
    // 4. performance.getEntries / getEntriesByType / getEntriesByName
    //    — scrub precise timing from Resource Timing entries
    // =============================================
    const fuzzEntry = (entry) => {
      const fuzzed = Object.create(Object.getPrototypeOf(entry));
      for (const key of Object.keys(entry.toJSON ? entry.toJSON() : entry)) {
        let val = entry[key];
        if (typeof val === 'number' && val > 0 && key !== 'workerStart') {
          val = fuzz(val);
        }
        Object.defineProperty(fuzzed, key, { value: val, enumerable: true, configurable: true });
      }
      return fuzzed;
    };

    const wrapEntries = (fn) => function(...args) {
      try {
        return fn.apply(this, args).map(fuzzEntry);
      } catch(e) {
        return fn.apply(this, args);
      }
    };

    const ge  = Performance.prototype.getEntries;
    const gebt = Performance.prototype.getEntriesByType;
    const gebn = Performance.prototype.getEntriesByName;

    if (ge)   { const w = wrapEntries(ge);   window.__pbrowser_cloak(w, 'function getEntries() { [native code] }');         Performance.prototype.getEntries        = w; }
    if (gebt) { const w = wrapEntries(gebt); window.__pbrowser_cloak(w, 'function getEntriesByType() { [native code] }');   Performance.prototype.getEntriesByType  = w; }
    if (gebn) { const w = wrapEntries(gebn); window.__pbrowser_cloak(w, 'function getEntriesByName() { [native code] }');   Performance.prototype.getEntriesByName  = w; }

    // =============================================
    // 5. performance.timeOrigin  (M-8 audit fix)
    // High-precision Unix epoch ms when page started loading.
    // Unfuzzed, this leaks real device boot patterns. Round to 1s + add jitter.
    // =============================================
    const _origTODesc = Object.getOwnPropertyDescriptor(Performance.prototype, 'timeOrigin')
                     || Object.getOwnPropertyDescriptor(performance, 'timeOrigin');
    if (_origTODesc && _origTODesc.get) {
      const _origTOGetter = _origTODesc.get;
      const _spoofedTOGetter = function() {
        const real    = _origTOGetter.call(this);
        const rounded = Math.round(real / 1000) * 1000; // round to nearest second
        const jitter  = (nextRand() * 2 - 1) * JITTER_MAX;
        return rounded + jitter;
      };
      window.__pbrowser_cloak(_spoofedTOGetter, 'function get timeOrigin() { [native code] }');
      try {
        Object.defineProperty(Performance.prototype, 'timeOrigin', {
          get: _spoofedTOGetter, configurable: true, enumerable: true
        });
      } catch(e) {
        Object.defineProperty(performance, 'timeOrigin', {
          get: _spoofedTOGetter, configurable: true, enumerable: true
        });
      }
    }

  } catch(e) {}
})();
''';
  }
}
