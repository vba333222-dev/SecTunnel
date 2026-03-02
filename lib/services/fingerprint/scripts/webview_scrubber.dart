import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Webview Context Detection Scrubbing
class WebviewScrubber {
  static String generate(FingerprintConfig config) {
    return '''
// ===== WEBVIEW CONTEXT SCRUBBER =====
(() => {
  try {
    // 1. Annihilate Flutter & Default Android WebView Global Pointers
    // These globals are often automatically injected by WebView engines or Flutter plugins
    const knownWebViewLeaks = [
      // Flutter / InAppWebView globals
      'flutter_inappwebview',
      'flutter',
      'Flutter',
      '__flutter_inappwebview_shared_dictionary',
      '_flutter',
      // Generic Android/WebView bridges
      'WebView',
      'android',
      'Android',
      '__bridge',
      // Chromium DevTools / AutoDriver residuals
      '__gCrWeb',
      'cdc_adoQpoasnfa76pfcZLmcfl_Array',
      'cdc_adoQpoasnfa76pfcZLmcfl_Promise',
      'cdc_adoQpoasnfa76pfcZLmcfl_Symbol',
      '\$chrome_asyncScriptInfo',
      // Chrome extension injection markers
      '__crWeb',
      '_phantom',
      'callPhantom',
      '_selenium',
      'selenium',
      '__webdriver_evaluate',
      '__selenium_evaluate',
      '__fxdriver_evaluate',
    ];

    knownWebViewLeaks.forEach(leak => {
      try {
        if (window[leak] !== undefined) {
           delete window[leak];
        }
      } catch(e) {}
    });

    // 2. Erase generic WebView UserAgent identifiers not covered deeply
    // While navigator.userAgent is masked in navigator_spoof.dart, Android WebViews 
    // sometimes leak secondary properties like vendorSub
    try {
      if (navigator.vendorSub !== undefined) {
          const spoofedVendorSub = function() { return ""; };
          Object.defineProperty(spoofedVendorSub, 'name', { value: 'get vendorSub', configurable: true });
          window.__pbrowser_cloak(spoofedVendorSub, 'function get vendorSub() { [native code] }');
          
          Object.defineProperty(Navigator.prototype, 'vendorSub', {
            get: spoofedVendorSub,
            set: undefined,
            enumerable: true,
            configurable: true
          });
      }
    } catch(e) {}
    
    // 3. Delete specific Android Error mappings
    // Some advanced bots trigger an error and check the Error.prototype.stack format.
    // While hard to completely mask in V8, we can delete explicit bridge namespaces.
    try {
      if (window.java !== undefined) {
          delete window.java;
      }
    } catch(e) {}

  } catch(e) {}
})();
''';
  }
}
