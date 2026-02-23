import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Hardware API Polyfills.
/// Injects mock navigator.usb, bluetooth, hid, serial, keyboard interfaces
/// on Desktop profiles to prevent "missing API" bot-detection signals.
class HardwareApiPolyfill {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win32') ||
        platform.contains('macintel') ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    if (!isDesktop) {
      return '// [HardwareApiPolyfill] Mobile profile — hardware APIs intact.';
    }

    return r'''
// ===== HARDWARE API POLYFILLS (Desktop Chrome Interfaces) =====
(() => {
  try {

    // --- Shared: user-cancelled rejection factory ---
    // Real Chrome throws DOMException when user cancels hardware picker dialog
    const userCancelledError = () =>
      Promise.reject(
        Object.assign(new DOMException('User cancelled the requestDevice() chooser.',
          'NotFoundError'), { code: 8 })
      );

    const securityError = (msg) =>
      Promise.reject(
        Object.assign(new DOMException(msg || 'Access denied.', 'SecurityError'),
          { code: 18 })
      );

    // =============================================
    // 1. navigator.usb  (WebUSB API)
    // =============================================
    if (!navigator.usb) {
      const mockUsb = {
        getDevices:         () => Promise.resolve([]),
        requestDevice:      (filters) => userCancelledError(),
        addEventListener:   function() {},
        removeEventListener:function() {},
        dispatchEvent:      function() { return true; },
        onconnect:    null,
        ondisconnect: null,
      };
      window.__pbrowser_cloak(mockUsb.getDevices,    'function getDevices() { [native code] }');
      window.__pbrowser_cloak(mockUsb.requestDevice, 'function requestDevice() { [native code] }');

      Object.defineProperty(Navigator.prototype, 'usb', {
        get: function() { return mockUsb; },
        enumerable: true,
        configurable: true
      });
    }

    // =============================================
    // 2. navigator.bluetooth  (Web Bluetooth API)
    // =============================================
    if (!navigator.bluetooth) {
      const mockBluetooth = {
        getAvailability:    () => Promise.resolve(true),
        getDevices:         () => Promise.resolve([]),
        requestDevice:      (options) => userCancelledError(),
        addEventListener:   function() {},
        removeEventListener:function() {},
        dispatchEvent:      function() { return true; },
        onavailabilitychanged: null,
      };
      window.__pbrowser_cloak(mockBluetooth.getAvailability, 'function getAvailability() { [native code] }');
      window.__pbrowser_cloak(mockBluetooth.requestDevice,   'function requestDevice() { [native code] }');

      Object.defineProperty(Navigator.prototype, 'bluetooth', {
        get: function() { return mockBluetooth; },
        enumerable: true,
        configurable: true
      });
    }

    // =============================================
    // 3. navigator.hid  (WebHID API)
    // =============================================
    if (!navigator.hid) {
      const mockHid = {
        getDevices:         () => Promise.resolve([]),
        requestDevice:      (options) => userCancelledError(),
        addEventListener:   function() {},
        removeEventListener:function() {},
        dispatchEvent:      function() { return true; },
        onconnect:    null,
        ondisconnect: null,
      };
      window.__pbrowser_cloak(mockHid.getDevices,    'function getDevices() { [native code] }');
      window.__pbrowser_cloak(mockHid.requestDevice, 'function requestDevice() { [native code] }');

      Object.defineProperty(Navigator.prototype, 'hid', {
        get: function() { return mockHid; },
        enumerable: true,
        configurable: true
      });
    }

    // =============================================
    // 4. navigator.serial  (Web Serial API)
    // =============================================
    if (!navigator.serial) {
      const mockSerial = {
        getPorts:           () => Promise.resolve([]),
        requestPort:        (options) => userCancelledError(),
        addEventListener:   function() {},
        removeEventListener:function() {},
        dispatchEvent:      function() { return true; },
        onconnect:    null,
        ondisconnect: null,
      };
      window.__pbrowser_cloak(mockSerial.getPorts,     'function getPorts() { [native code] }');
      window.__pbrowser_cloak(mockSerial.requestPort,  'function requestPort() { [native code] }');

      Object.defineProperty(Navigator.prototype, 'serial', {
        get: function() { return mockSerial; },
        enumerable: true,
        configurable: true
      });
    }

    // =============================================
    // 5. navigator.keyboard  (Keyboard Lock API)
    // =============================================
    if (!navigator.keyboard) {
      const mockKeyboard = {
        lock:               (keyCodes) => Promise.resolve(),
        unlock:             () => undefined,
        getLayoutMap:       () => Promise.resolve(new Map()),
        addEventListener:   function() {},
        removeEventListener:function() {},
      };
      window.__pbrowser_cloak(mockKeyboard.lock,         'function lock() { [native code] }');
      window.__pbrowser_cloak(mockKeyboard.unlock,       'function unlock() { [native code] }');
      window.__pbrowser_cloak(mockKeyboard.getLayoutMap, 'function getLayoutMap() { [native code] }');

      Object.defineProperty(Navigator.prototype, 'keyboard', {
        get: function() { return mockKeyboard; },
        enumerable: true,
        configurable: true
      });
    }

    // =============================================
    // 6. navigator.wakeLock  (Screen Wake Lock API — present on Desktop Chrome)
    // =============================================
    if (!navigator.wakeLock) {
      const mockWakeLock = {
        request: (type) => Promise.resolve({
          released: false,
          type: type || 'screen',
          release: function() {
            this.released = true;
            return Promise.resolve();
          },
          addEventListener:   function() {},
          removeEventListener:function() {},
          onrelease: null
        })
      };
      window.__pbrowser_cloak(mockWakeLock.request, 'function request() { [native code] }');

      Object.defineProperty(Navigator.prototype, 'wakeLock', {
        get: function() { return mockWakeLock; },
        enumerable: true,
        configurable: true
      });
    }

  } catch(e) {}
})();
''';
  }
}
