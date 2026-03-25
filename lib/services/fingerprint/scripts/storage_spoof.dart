import 'package:SecTunnel/models/fingerprint_config.dart';

/// JavaScript code generator for File System Access API polyfills
/// and Storage Quota spoofing. Injects Desktop-appropriate APIs and
/// reports hard drive quota consistent with a high-end PC.
class StorageSpoof {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win32') ||
        platform.contains('macintel') ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    if (!isDesktop) {
      return '// [StorageSpoof] Mobile profile — storage APIs intact.';
    }

    final seed = config.canvasNoiseSalt.hashCode.abs();
    // Deterministic quota: 150 GB – 499 GB range (in bytes)
    final quotaGB  = 150 + (seed % 350);                         // 150–499 GB
    final usageGB  = 2 + (seed % 18);                            // 2–19 GB used
    final quotaBytes = quotaGB * 1024 * 1024 * 1024;
    final usageBytes = usageGB * 1024 * 1024 * 1024;

    return '''
// ===== FILE SYSTEM ACCESS API & STORAGE QUOTA SPOOFING =====
(() => {
  try {

    // User-aborted file picker error (standard Chrome Desktop behavior)
    const userAbortedError = () =>
      Promise.reject(
        Object.assign(new DOMException('The user aborted a request.', 'AbortError'),
          { code: 20 })
      );

    // ================================================================
    // 1. window.showOpenFilePicker  (File System Access API)
    // ================================================================
    if (!window.showOpenFilePicker) {
      const showOpenFilePicker = async function(options) {
        return userAbortedError();
      };
      window.__pbrowser_cloak(showOpenFilePicker, 'function showOpenFilePicker() { [native code] }');
      Object.defineProperty(window, 'showOpenFilePicker', {
        value: showOpenFilePicker, writable: false, enumerable: true, configurable: true
      });
    }

    // ================================================================
    // 2. window.showSaveFilePicker
    // ================================================================
    if (!window.showSaveFilePicker) {
      const showSaveFilePicker = async function(options) {
        return userAbortedError();
      };
      window.__pbrowser_cloak(showSaveFilePicker, 'function showSaveFilePicker() { [native code] }');
      Object.defineProperty(window, 'showSaveFilePicker', {
        value: showSaveFilePicker, writable: false, enumerable: true, configurable: true
      });
    }

    // ================================================================
    // 3. window.showDirectoryPicker
    // ================================================================
    if (!window.showDirectoryPicker) {
      const showDirectoryPicker = async function(options) {
        return userAbortedError();
      };
      window.__pbrowser_cloak(showDirectoryPicker, 'function showDirectoryPicker() { [native code] }');
      Object.defineProperty(window, 'showDirectoryPicker', {
        value: showDirectoryPicker, writable: false, enumerable: true, configurable: true
      });
    }

    // ================================================================
    // 4. navigator.storage.estimate() — StorageManager quota
    // Android: ~12 GB quota. Desktop Chrome: >> 100 GB
    // ================================================================
    if (navigator.storage && navigator.storage.estimate) {
      const QUOTA_BYTES = $quotaBytes;
      const USAGE_BYTES = $usageBytes;

      const spoofedEstimate = function() {
        return Promise.resolve({
          quota: QUOTA_BYTES,
          usage: USAGE_BYTES,
          usageDetails: {
            caches:        Math.floor(USAGE_BYTES * 0.15),
            indexedDB:     Math.floor(USAGE_BYTES * 0.35),
            serviceWorkerRegistrations: Math.floor(USAGE_BYTES * 0.05),
            sessionStorage: Math.floor(USAGE_BYTES * 0.05),
            localStorage:   Math.floor(USAGE_BYTES * 0.40),
          }
        });
      };
      window.__pbrowser_cloak(spoofedEstimate, 'function estimate() { [native code] }');
      try {
        Object.defineProperty(navigator.storage, 'estimate', {
          value: spoofedEstimate, writable: false, enumerable: true, configurable: true
        });
      } catch(e) {
        navigator.storage.estimate = spoofedEstimate;
      }
    }

    // ================================================================
    // 5. navigator.storage.persist() — Android often returns false
    //    (unrequested). Chrome Desktop usually returns true for installed PWAs.
    // ================================================================
    if (navigator.storage && navigator.storage.persist) {
      const spoofedPersist = function() { return Promise.resolve(true); };
      window.__pbrowser_cloak(spoofedPersist, 'function persist() { [native code] }');
      try {
        Object.defineProperty(navigator.storage, 'persist', {
          value: spoofedPersist, writable: false, enumerable: true, configurable: true
        });
      } catch(e) {
        navigator.storage.persist = spoofedPersist;
      }
    }

    // ================================================================
    // 6. navigator.storage.persisted() — returns true on Desktop
    // ================================================================
    if (navigator.storage && navigator.storage.persisted) {
      const spoofedPersisted = function() { return Promise.resolve(true); };
      window.__pbrowser_cloak(spoofedPersisted, 'function persisted() { [native code] }');
      try {
        Object.defineProperty(navigator.storage, 'persisted', {
          value: spoofedPersisted, writable: false, enumerable: true, configurable: true
        });
      } catch(e) {
        navigator.storage.persisted = spoofedPersisted;
      }
    }

  } catch(e) {}
})();
''';
  }
}
