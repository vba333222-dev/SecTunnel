import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for CSS Media Queries Spoofing.
/// Intercepts window.matchMedia to return Desktop-consistent pointer/hover results,
/// preventing bot detection via CSS capability fingerprinting.
class MatchMediaSpoof {
  static String generate(FingerprintConfig config) {
    // Determine if this profile is Desktop or Mobile
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win32') ||
        platform.contains('macintel') ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    // For mobile profiles, skip — coarse pointer is accurate
    if (!isDesktop) {
      return '// [MatchMediaSpoof] Mobile profile — pointer media queries intact.';
    }

    return r'''
// ===== CSS MEDIA QUERIES SPOOFING (DESKTOP MODE) =====
(() => {
  try {
    const originalMatchMedia = window.matchMedia.bind(window);

    // Queries that indicate mobile/touch — must return false for Desktop
    const FORCE_FALSE_PATTERNS = [
      /\(pointer\s*:\s*coarse\)/i,
      /\(any-pointer\s*:\s*coarse\)/i,
      /\(hover\s*:\s*none\)/i,
      /\(any-hover\s*:\s*none\)/i,
      /\(pointer\s*:\s*none\)/i,
      // Android/iOS accessibility features not present on Desktop
      /\(forced-colors\s*:\s*active\)/i,   // Windows High Contrast — desktop has it, not Android
      /\(inverted-colors\s*:\s*inverted\)/i,
      /\(prefers-reduced-data\s*:\s*reduce\)/i,
      /\(prefers-contrast\s*:\s*forced\)/i,
    ];

    // Queries that indicate Desktop precision input — must return true for Desktop
    const FORCE_TRUE_PATTERNS = [
      /\(pointer\s*:\s*fine\)/i,
      /\(any-pointer\s*:\s*fine\)/i,
      /\(hover\s*:\s*hover\)/i,
      /\(any-hover\s*:\s*hover\)/i,
      // Desktop-specific feature queries
      /\(prefers-contrast\s*:\s*no-preference\)/i,
      /\(forced-colors\s*:\s*none\)/i,
      /\(inverted-colors\s*:\s*none\)/i,
      /\(-webkit-overflow-scrolling\)/i,   // Desktop Chrome supports this
      /\(update\s*:\s*fast\)/i,            // Display update rate — Desktop is always 'fast'
    ];

    // Build a fake MediaQueryList object matching the browser API
    const makeFakeMediaQueryList = (query, matchesValue) => {
      // Try to use the real MediaQueryList for non-manipulated queries
      // This ensures addListener/removeListener still work
      let base;
      try {
        base = originalMatchMedia(query);
      } catch(e) {
        base = null;
      }

      const mql = Object.create(
        typeof MediaQueryList !== 'undefined' ? MediaQueryList.prototype : Object.prototype
      );

      Object.defineProperty(mql, 'matches', {
        get: () => matchesValue,
        enumerable: true,
        configurable: true
      });

      Object.defineProperty(mql, 'media', {
        value: query,
        enumerable: true,
        configurable: true
      });

      // Event listener passthrough to the real MQL if available
      mql.addEventListener    = base ? base.addEventListener.bind(base)    : function() {};
      mql.removeEventListener = base ? base.removeEventListener.bind(base) : function() {};
      mql.addListener         = base ? base.addListener.bind(base)         : function() {};
      mql.removeListener      = base ? base.removeListener.bind(base)      : function() {};
      mql.dispatchEvent       = base ? base.dispatchEvent.bind(base)       : function() { return true; };
      mql.onchange            = null;

      return mql;
    };

    const spoofedMatchMedia = function(query) {
      if (!query) return originalMatchMedia(query);

      const q = String(query);

      // Check if query should be forced false (mobile indicator)
      for (const pattern of FORCE_FALSE_PATTERNS) {
        if (pattern.test(q)) {
          return makeFakeMediaQueryList(q, false);
        }
      }

      // Check if query should be forced true (desktop indicator)
      for (const pattern of FORCE_TRUE_PATTERNS) {
        if (pattern.test(q)) {
          return makeFakeMediaQueryList(q, true);
        }
      }

      // All other queries (dark mode, min-width, etc.) — pass through naturally
      return originalMatchMedia(q);
    };

    window.__pbrowser_cloak(spoofedMatchMedia, 'function matchMedia() { [native code] }');
    window.matchMedia = spoofedMatchMedia;

  } catch(e) {}
})();
''';
  }
}
