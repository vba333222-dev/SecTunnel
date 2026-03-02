import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Hardware Sensor / Touch API Spoofing.
/// Conditionally removes all mobile-exclusive touch and motion APIs
/// when the active profile is emulating a Desktop OS.
class HardwareSensorSpoof {
  static String generate(FingerprintConfig config) {
    // Detect Desktop platforms: Win32, MacIntel, Linux x86_64
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win32') ||
        platform.contains('macintel') ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    // If Mobile profile, skip scrubbing - leave APIs intact
    if (!isDesktop) {
      return '// [HardwareSensorSpoof] Mobile profile - sensor APIs intact.';
    }

    return '''
// ===== HARDWARE SENSOR & TOUCH API SCRUBBER (DESKTOP MODE) =====
(() => {
  try {

    // 1. Force navigator.maxTouchPoints to 0 (Desktop non-touchscreen)
    const spoofedMaxTouchPoints = function() { return 0; };
    window.__pbrowser_cloak(spoofedMaxTouchPoints, 'function get maxTouchPoints() { [native code] }');
    Object.defineProperty(Navigator.prototype, 'maxTouchPoints', {
      get: spoofedMaxTouchPoints,
      set: undefined,
      enumerable: true,
      configurable: true
    });

    // Also cover the legacy msMaxTouchPoints property
    try {
      const spoofedMsMaxTouchPoints = function() { return 0; };
      window.__pbrowser_cloak(spoofedMsMaxTouchPoints, 'function get msMaxTouchPoints() { [native code] }');
      Object.defineProperty(Navigator.prototype, 'msMaxTouchPoints', {
        get: spoofedMsMaxTouchPoints,
        set: undefined,
        enumerable: true,
        configurable: true
      });
    } catch(e) {}

    // 2. Delete touch event handlers from window and document
    const touchProps = [
      'ontouchstart', 'ontouchend', 'ontouchmove', 'ontouchcancel'
    ];
    touchProps.forEach(prop => {
      try {
        delete window[prop];
        delete document[prop];
      } catch(e) {}
      // Forcefully define as undefined with configurable=false for extra hardening
      try {
        Object.defineProperty(window, prop, {
          value: undefined,
          writable: false,
          enumerable: false,
          configurable: false
        });
      } catch(e) {}
    });

    // 3. Remove the Touch, TouchEvent, and TouchList constructors
    // FingerprintJS checks for `'TouchEvent' in window`
    const touchConstructors = ['Touch', 'TouchEvent', 'TouchList'];
    touchConstructors.forEach(name => {
      try {
        delete window[name];
      } catch(e) {}
    });

    // 4. Suppress DeviceMotionEvent and DeviceOrientationEvent
    // Override addEventListener to silently swallow these listener registrations
    const originalAddEventListener = EventTarget.prototype.addEventListener;
    const blockedSensorEvents = new Set([
      'devicemotion',
      'deviceorientation',
      'deviceorientationabsolute'
    ]);

    const spoofedAddEventListener = function(type, listener, options) {
      if (blockedSensorEvents.has(type ? type.toLowerCase() : '')) {
        // Silently drop the listener registration - never fires
        return;
      }
      return originalAddEventListener.apply(this, arguments);
    };

    window.__pbrowser_cloak(spoofedAddEventListener, 'function addEventListener() { [native code] }');
    EventTarget.prototype.addEventListener = spoofedAddEventListener;

    // 5. Also null any ondeviceorientation / ondevicemotion handlers
    const sensorHandlers = [
      'ondevicemotion',
      'ondeviceorientation',
      'ondeviceorientationabsolute'
    ];
    sensorHandlers.forEach(prop => {
      try {
        delete window[prop];
      } catch(e) {}
      try {
        Object.defineProperty(window, prop, {
          value: null,
          writable: false,
          enumerable: false,
          configurable: false
        });
      } catch(e) {}
    });

    // 6. Nullify DeviceMotionEvent and DeviceOrientationEvent constructors
    // so scripts using `typeof DeviceMotionEvent !== 'undefined'` get false
    const sensorConstructors = ['DeviceMotionEvent', 'DeviceOrientationEvent'];
    sensorConstructors.forEach(name => {
      try {
        delete window[name];
      } catch(e) {}
    });

  } catch(globalErr) {}
})();
''';
  }
}
