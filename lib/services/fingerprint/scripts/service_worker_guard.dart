import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for ServiceWorker Scope Protection (H-1 audit fix).
/// Intercepts navigator.serviceWorker.register() to prepend the spoofing
/// header into every registered Service Worker script.
class ServiceWorkerGuard {
  static String generate(FingerprintConfig config) {
    final userAgent          = config.userAgent.replaceAll("'", "\\'");
    final platform           = config.platform.replaceAll("'", "\\'");
    final language           = config.language.replaceAll("'", "\\'");
    final hardwareConcurrency = config.hardwareConcurrency;
    final deviceMemory        = config.deviceMemory;

    return '''
// ===== SERVICE WORKER SCOPE PROTECTION (H-1 Audit Fix) =====
// A Service Worker runs in its own scope where our main-world injections cannot
// reach. We intercept navigator.serviceWorker.register() to create a wrapper
// SW script that first applies the spoofing header, then imports the real SW.
(() => {
  try {
    if (!navigator.serviceWorker || !navigator.serviceWorker.register) return;

    // The JS snippet injected at the TOP of every registered Service Worker
    const SW_SPOOF_HEADER = `
// ----- PBrowser SW Shield -----
(function() {
  try {
    const _def = (obj, prop, val) => {
      try {
        Object.defineProperty(obj, prop, {
          get: function() { return val; },
          configurable: true, enumerable: true
        });
      } catch(e) {}
    };

    // WorkerNavigator properties — same API surface as WorkerSpoof
    if (typeof WorkerNavigator !== 'undefined') {
      _def(WorkerNavigator.prototype, 'userAgent',           '$userAgent');
      _def(WorkerNavigator.prototype, 'platform',            '$platform');
      _def(WorkerNavigator.prototype, 'language',            '$language');
      _def(WorkerNavigator.prototype, 'hardwareConcurrency', $hardwareConcurrency);
      _def(WorkerNavigator.prototype, 'deviceMemory',        $deviceMemory);
      _def(WorkerNavigator.prototype, 'webdriver',           false);
    }
    if (typeof self !== 'undefined' && self.navigator) {
      _def(self.navigator, 'userAgent',           '$userAgent');
      _def(self.navigator, 'platform',            '$platform');
      _def(self.navigator, 'hardwareConcurrency', $hardwareConcurrency);
      _def(self.navigator, 'deviceMemory',        $deviceMemory);
    }
  } catch(e) {}
})();
// ----- End PBrowser SW Shield -----
`;

    const origRegister = ServiceWorkerContainer.prototype.register;

    const spoofedRegister = async function(scriptURL, options) {
      try {
        const resp    = await fetch(scriptURL, { credentials: 'same-origin' });
        if (!resp.ok) throw new Error('fetch failed');
        const origCode = await resp.text();
        const combined = SW_SPOOF_HEADER + '\\n' + origCode;
        const blob     = new Blob([combined], { type: 'application/javascript' });
        const blobURL  = URL.createObjectURL(blob);

        // Register the patched blob as the SW
        const reg = await origRegister.call(this, blobURL, options);
        setTimeout(() => URL.revokeObjectURL(blobURL), 5000);
        return reg;
      } catch(e) {
        // CORS / network error fallback: register original without spoofing
        return origRegister.call(this, scriptURL, options);
      }
    };

    window.__pbrowser_cloak(spoofedRegister, 'function register() { [native code] }');

    try {
      Object.defineProperty(ServiceWorkerContainer.prototype, 'register', {
        value: spoofedRegister, writable: false, enumerable: true, configurable: true
      });
    } catch(e) {
      navigator.serviceWorker.register = spoofedRegister;
    }

  } catch(e) {}
})();
''';
  }
}
