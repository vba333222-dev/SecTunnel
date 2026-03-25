import 'package:SecTunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Geolocation API Spoofing.
/// Returns timezone-consistent coordinates when sites call getCurrentPosition/watchPosition.
/// Prevents sites from detecting Android-native GPS vs Desktop Geolocation API behaviour.
class GeolocationSpoof {
  static String generate(FingerprintConfig config) {
    // Timezone → plausible city coordinates mapping
    final tz = config.timezone.toLowerCase();

    // Determine coordinates from timezone
    final coords = _coordsFromTimezone(tz, config.canvasNoiseSalt.hashCode.abs());
    final lat  = coords['lat']!;
    final lon  = coords['lon']!;
    final acc  = 20.0 + (config.canvasNoiseSalt.hashCode.abs() % 80); // 20–99m accuracy

    return '''
// ===== GEOLOCATION API SPOOFING =====
// Returns timezone-consistent coordinates; prevents GPS vs Desktop API detection.
(() => {
  try {
    if (!navigator.geolocation) return;

    const SPOOF_LAT = $lat;
    const SPOOF_LON = $lon;
    const SPOOF_ACC = $acc;

    // Build a frozen PositionError stub for denied/unavailable cases
    const makeFakePosition = () => {
      const coords = Object.create(
        typeof GeolocationCoordinates !== 'undefined'
          ? GeolocationCoordinates.prototype : Object.prototype
      );
      Object.defineProperties(coords, {
        latitude:         { value: SPOOF_LAT,         enumerable: true, configurable: true },
        longitude:        { value: SPOOF_LON,         enumerable: true, configurable: true },
        accuracy:         { value: SPOOF_ACC,         enumerable: true, configurable: true },
        altitude:         { value: null,              enumerable: true, configurable: true },
        altitudeAccuracy: { value: null,              enumerable: true, configurable: true },
        heading:          { value: null,              enumerable: true, configurable: true },
        speed:            { value: null,              enumerable: true, configurable: true },
      });

      const pos = Object.create(
        typeof GeolocationPosition !== 'undefined'
          ? GeolocationPosition.prototype : Object.prototype
      );
      Object.defineProperties(pos, {
        coords:    { value: coords,       enumerable: true, configurable: true },
        timestamp: { value: Date.now(),   enumerable: true, configurable: true },
      });
      return pos;
    };

    // Override getCurrentPosition
    const origGetCurrentPosition = Geolocation.prototype.getCurrentPosition;
    const spoofedGetCurrentPosition = function(successCb, errorCb, options) {
      try {
        // Call native — if user has granted permission, intercept the result
        origGetCurrentPosition.call(this,
          (realPos) => {
            // Replace with spoofed position
            try { successCb(makeFakePosition()); } catch(e) { successCb(realPos); }
          },
          (err) => {
            // If denied/unavailable, still return spoofed position (Desktop behavior)
            try { successCb(makeFakePosition()); } catch(e2) {
              if (errorCb) errorCb(err);
            }
          },
          options
        );
      } catch(e) {
        try { successCb(makeFakePosition()); } catch(e2) {
          if (errorCb) errorCb(e);
        }
      }
    };
    window.__pbrowser_cloak(spoofedGetCurrentPosition,
      'function getCurrentPosition() { [native code] }');
    Geolocation.prototype.getCurrentPosition = spoofedGetCurrentPosition;

    // Override watchPosition — return spoofed position, clean up native watcher
    const origWatchPosition = Geolocation.prototype.watchPosition;
    const spoofedWatchPosition = function(successCb, errorCb, options) {
      let watchId;
      try {
        watchId = origWatchPosition.call(this,
          (realPos) => {
            try { successCb(makeFakePosition()); } catch(e) { successCb(realPos); }
          },
          errorCb,
          options
        );
      } catch(e) {
        // If watchPosition fails outright, call success once with fake position
        try { successCb(makeFakePosition()); } catch(e2) {}
        watchId = Math.floor(Math.random() * 10000); // fake watchId
      }
      return watchId;
    };
    window.__pbrowser_cloak(spoofedWatchPosition,
      'function watchPosition() { [native code] }');
    Geolocation.prototype.watchPosition = spoofedWatchPosition;

  } catch(e) {}
})();
''';
  }

  /// Returns plausible lat/lon for the given timezone string.
  static Map<String, double> _coordsFromTimezone(String tz, int seed) {
    // Micro-jitter within ±0.05° (≈ 5km) for uniqueness per profile
    final jitter = (seed % 1000) / 10000.0;

    if (tz.contains('asia/jakarta') || tz.contains('wib'))      return {'lat': -6.2088 + jitter, 'lon': 106.8456 + jitter};
    if (tz.contains('asia/makassar') || tz.contains('wita'))    return {'lat': -5.1477 + jitter, 'lon': 119.4327 + jitter};
    if (tz.contains('asia/jayapura') || tz.contains('wit'))     return {'lat': -2.5337 + jitter, 'lon': 140.7180 + jitter};
    if (tz.contains('asia/singapore'))                           return {'lat': 1.3521  + jitter, 'lon': 103.8198 + jitter};
    if (tz.contains('asia/kuala_lumpur'))                        return {'lat': 3.1390  + jitter, 'lon': 101.6869 + jitter};
    if (tz.contains('asia/bangkok'))                             return {'lat': 13.7563 + jitter, 'lon': 100.5018 + jitter};
    if (tz.contains('asia/tokyo'))                               return {'lat': 35.6762 + jitter, 'lon': 139.6503 + jitter};
    if (tz.contains('asia/seoul'))                               return {'lat': 37.5665 + jitter, 'lon': 126.9780 + jitter};
    if (tz.contains('asia/shanghai') || tz.contains('asia/chongqing')) return {'lat': 31.2304 + jitter, 'lon': 121.4737 + jitter};
    if (tz.contains('asia/kolkata') || tz.contains('india'))    return {'lat': 28.6139 + jitter, 'lon': 77.2090 + jitter};
    if (tz.contains('europe/london'))                            return {'lat': 51.5074 + jitter, 'lon': -0.1278 + jitter};
    if (tz.contains('europe/berlin') || tz.contains('europe/amsterdam')) return {'lat': 52.5200 + jitter, 'lon': 13.4050 + jitter};
    if (tz.contains('europe/paris'))                             return {'lat': 48.8566 + jitter, 'lon': 2.3522 + jitter};
    if (tz.contains('america/new_york'))                         return {'lat': 40.7128 + jitter, 'lon': -74.0060 + jitter};
    if (tz.contains('america/los_angeles'))                      return {'lat': 34.0522 + jitter, 'lon': -118.2437 + jitter};
    if (tz.contains('america/chicago'))                          return {'lat': 41.8781 + jitter, 'lon': -87.6298 + jitter};
    if (tz.contains('australia/sydney'))                         return {'lat': -33.8688 + jitter, 'lon': 151.2093 + jitter};
    // Fallback: somewhere in Central Asia
    return {'lat': 0.0 + jitter, 'lon': 0.0 + jitter};
  }
}
