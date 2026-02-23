import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Web Worker / SharedWorker fingerprint protection.
/// Uses the Blob URL Prepend technique to inject navigator spoofing into Worker sandboxes.
class WorkerSpoof {
  static String generate(FingerprintConfig config) {
    final userAgent = config.userAgent.replaceAll("'", "\\'");
    final hardwareConcurrency = config.hardwareConcurrency;
    final deviceMemory = config.deviceMemory;
    final platform = config.platform.replaceAll("'", "\\'");
    final language = config.language.replaceAll("'", "\\'");

    return '''
// ===== WEB WORKER / SERVICE WORKER FINGERPRINT SHIELD =====
(() => {
  try {
    // ---- The spoofing header script injected at the TOP of every Worker ----
    // This is the raw JS code prepended to each worker's script before execution.
    const WORKER_SPOOF_HEADER = `
// ----- PBrowser Worker Shield -----
(function() {
  try {
    const _defineWorkerProp = (obj, prop, value) => {
      try {
        Object.defineProperty(obj, prop, {
          get: function() { return value; },
          configurable: true, enumerable: true
        });
      } catch(e) {}
    };

    if (typeof WorkerNavigator !== 'undefined') {
      _defineWorkerProp(WorkerNavigator.prototype, 'userAgent', '$userAgent');
      _defineWorkerProp(WorkerNavigator.prototype, 'platform', '$platform');
      _defineWorkerProp(WorkerNavigator.prototype, 'language', '$language');
      _defineWorkerProp(WorkerNavigator.prototype, 'hardwareConcurrency', $hardwareConcurrency);
      _defineWorkerProp(WorkerNavigator.prototype, 'deviceMemory', $deviceMemory);
      _defineWorkerProp(WorkerNavigator.prototype, 'webdriver', false);
    }
    
    // Fallback: override self.navigator directly in case WorkerNavigator prototype is inaccessible
    if (typeof self !== 'undefined' && self.navigator) {
      _defineWorkerProp(self.navigator, 'userAgent', '$userAgent');
      _defineWorkerProp(self.navigator, 'platform', '$platform');
      _defineWorkerProp(self.navigator, 'hardwareConcurrency', $hardwareConcurrency);
      _defineWorkerProp(self.navigator, 'deviceMemory', $deviceMemory);
    }
  } catch(e) {}
})();
// ----- End PBrowser Worker Shield -----
`;

    // ---- Helper: Fetch script, prepend header, return Blob URL ----
    const createSpoofedBlobUrl = async (originalUrl) => {
      try {
        const response = await fetch(originalUrl);
        const originalCode = await response.text();
        const combined = WORKER_SPOOF_HEADER + '\\n' + originalCode;
        const blob = new Blob([combined], { type: 'application/javascript' });
        return URL.createObjectURL(blob);
      } catch(e) {
        // Fallback: return a blob with just the header (may happen with cross-origin scripts)
        const blob = new Blob([WORKER_SPOOF_HEADER], { type: 'application/javascript' });
        return URL.createObjectURL(blob);
      }
    };

    // ---- Intercept the Worker constructor ----
    if (typeof Worker !== 'undefined') {
      const OriginalWorker = Worker;

      const SpoofedWorker = function(scriptURL, options) {
        // Handle Blob URLs (already inline) — prepend by decoding and re-blobbing
        if (typeof scriptURL === 'string' && scriptURL.startsWith('blob:')) {
          // For blob URLs, we convert to sync using an importScripts trick inside a new blob
          const wrappedCode = WORKER_SPOOF_HEADER + '\\nimportScripts(' + JSON.stringify(scriptURL) + ');';
          const wrappedBlob = new Blob([wrappedCode], { type: 'application/javascript' });
          const wrappedUrl = URL.createObjectURL(wrappedBlob);
          return new OriginalWorker(wrappedUrl, options);
        }

        // For standard URLs: create the worker first then modify (synchronous fallback)
        // We also create a shim worker that applies the header via importScripts trick
        if (typeof scriptURL === 'string') {
          const wrappedCode = WORKER_SPOOF_HEADER + '\\nimportScripts(' + JSON.stringify(scriptURL) + ');';
          const wrappedBlob = new Blob([wrappedCode], { type: 'application/javascript' });
          const wrappedUrl = URL.createObjectURL(wrappedBlob);
          try {
            return new OriginalWorker(wrappedUrl, options);
          } catch(e) {
            // CORS fallback — use the original URL directly
            return new OriginalWorker(scriptURL, options);
          }
        }

        return new OriginalWorker(scriptURL, options);
      };

      // Copy static properties
      SpoofedWorker.prototype = OriginalWorker.prototype;
      Object.setPrototypeOf(SpoofedWorker, OriginalWorker);

      window.__pbrowser_cloak(SpoofedWorker, 'function Worker() { [native code] }');
      window.Worker = SpoofedWorker;
    }

    // ---- Intercept the SharedWorker constructor ----
    if (typeof SharedWorker !== 'undefined') {
      const OriginalSharedWorker = SharedWorker;

      const SpoofedSharedWorker = function(scriptURL, options) {
        if (typeof scriptURL === 'string') {
          const wrappedCode = WORKER_SPOOF_HEADER + '\\nimportScripts(' + JSON.stringify(scriptURL) + ');';
          const wrappedBlob = new Blob([wrappedCode], { type: 'application/javascript' });
          const wrappedUrl = URL.createObjectURL(wrappedBlob);
          try {
            return new OriginalSharedWorker(wrappedUrl, options);
          } catch(e) {
            return new OriginalSharedWorker(scriptURL, options);
          }
        }
        return new OriginalSharedWorker(scriptURL, options);
      };

      SpoofedSharedWorker.prototype = OriginalSharedWorker.prototype;
      Object.setPrototypeOf(SpoofedSharedWorker, OriginalSharedWorker);

      window.__pbrowser_cloak(SpoofedSharedWorker, 'function SharedWorker() { [native code] }');
      window.SharedWorker = SpoofedSharedWorker;
    }

  } catch(e) {}
})();
''';
  }
}
