import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for Battery Status API spoofing
class BatterySpoof {
  static String generate(FingerprintConfig config) {
    // Deterministic seeding based on profile
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== BATTERY SPOOFING =====
(() => {
  try {
    if (!navigator.getBattery) return;
    
    const profileSeed = $seed;
    \${NativeUtils.seededRandomFunction()}
    const getRandom = seededRandom(profileSeed);
    
    // Generate deterministic but seemingly random battery state for this profile
    const level = parseFloat((0.2 + (getRandom() * 0.8)).toFixed(2)); // 20% to 100%
    const charging = getRandom() > 0.5;
    const chargingTime = charging ? Math.floor(getRandom() * 3600) : Infinity;
    const dischargingTime = charging ? Infinity : Math.floor(getRandom() * 14400);

    const originalGetBattery = navigator.getBattery;
    
    const spoofedGetBattery = function() {
      return originalGetBattery.call(this).then(battery => {
        // Intercept and proxy the returned BatteryManager promise result
        return new Proxy(battery, {
          get(target, prop, receiver) {
            if (prop === 'level') return level;
            if (prop === 'charging') return charging;
            if (prop === 'chargingTime') return chargingTime;
            if (prop === 'dischargingTime') return dischargingTime;
            
            const value = Reflect.get(target, prop, receiver);
            if (typeof value === 'function') {
              return value.bind(target);
            }
            return value;
          }
        });
      });
    };
    
    window.__pbrowser_cloak(spoofedGetBattery, 'function getBattery() { [native code] }');
    navigator.getBattery = spoofedGetBattery;
    
  } catch(e) {}
})();
''';
  }
}
