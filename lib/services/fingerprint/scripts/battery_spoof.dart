import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for Battery Status API spoofing
class BatterySpoof {
  static String generate(FingerprintConfig config) {
    // Deterministic seeding based on profile
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== BATTERY STATUS API SPOOFING =====
// Desktop Chrome policy: most Desktop machines appear as charging=true, level=1.0
// (device is always plugged in). Mobile profiles show realistic random battery.
(() => {
  try {
    if (!navigator.getBattery) return;

    const profileSeed = $seed;
    \${NativeUtils.seededRandomFunction()}
    const getRandom = seededRandom(profileSeed);

    // Determine profile type from navigator.platform
    const _platform = (navigator.platform || '').toLowerCase();
    const _isDesktop = _platform.includes('win') || _platform.includes('mac')
                    || _platform.includes('linux x86');

    // Desktop: always plugged in and full (most common state)
    // Mobile: randomized from seed
    const charging         = _isDesktop ? true  : (getRandom() > 0.4);
    const level            = _isDesktop ? 1.0   : parseFloat((0.2 + getRandom() * 0.78).toFixed(2));
    const chargingTime     = _isDesktop ? 0     : (charging ? Math.floor(getRandom() * 3600) : Infinity);
    const dischargingTime  = _isDesktop ? Infinity : (charging ? Infinity : Math.floor(getRandom() * 14400));

    const buildBatteryProxy = (battery) => new Proxy(battery, {
      get(target, prop, receiver) {
        switch(prop) {
          case 'level':           return level;
          case 'charging':        return charging;
          case 'chargingTime':    return chargingTime;
          case 'dischargingTime': return dischargingTime;
          case 'addEventListener':    return target.addEventListener.bind(target);
          case 'removeEventListener': return target.removeEventListener.bind(target);
          case 'dispatchEvent':       return target.dispatchEvent.bind(target);
          case 'onchargingchange':    return null;
          case 'onlevelchange':       return null;
          case 'onchargingtimechange':    return null;
          case 'ondischargingtimechange':  return null;
          default:
            const val = Reflect.get(target, prop, receiver);
            return typeof val === 'function' ? val.bind(target) : val;
        }
      }
    });

    // Override on Navigator.prototype for full interception
    const orig = navigator.getBattery;
    const spoofedGetBattery = function() {
      return orig.call(this).then(battery => buildBatteryProxy(battery));
    };

    window.__pbrowser_cloak(spoofedGetBattery, 'function getBattery() { [native code] }');

    try {
      Object.defineProperty(Navigator.prototype, 'getBattery', {
        value: spoofedGetBattery, writable: false, enumerable: true, configurable: true
      });
    } catch(e) {
      navigator.getBattery = spoofedGetBattery;
    }

  } catch(e) {}
})();
''';
  }
}
