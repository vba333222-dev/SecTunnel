import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for timezone and geolocation spoofing
/// CRITICAL: Synchronizes timezone with proxy IP location for consistency
class TimezoneSpoof {
  static String generate(FingerprintConfig config) {
    final timezone = NativeUtils.escapeJs(config.timezone);
    final latitude = config.geolocation?.latitude ?? 0.0;
    final longitude = config.geolocation?.longitude ?? 0.0;
    final accuracy = config.geolocation?.accuracy ?? 50.0;
    
    return '''
// ===== TIMEZONE & GEOLOCATION SPOOFING =====
(() => {
  const spoofedTimezone = '$timezone';
  const spoofedLatitude = $latitude;
  const spoofedLongitude = $longitude;
  const spoofedAccuracy = $accuracy;
  
  // ===== TIMEZONE SPOOFING =====
  
  // Override Intl.DateTimeFormat
  const OriginalDateTimeFormat = Intl.DateTimeFormat;
  
  Intl.DateTimeFormat = new Proxy(OriginalDateTimeFormat, {
    construct(target, args) {
      const instance = new target(...args);
      
      // Override resolvedOptions
      const originalResolvedOptions = instance.resolvedOptions;
      instance.resolvedOptions = function() {
        const options = originalResolvedOptions.call(this);
        options.timeZone = spoofedTimezone;
        return options;
      };
      
      return instance;
    }
  });
  
  // Make Intl.DateTimeFormat.prototype.resolvedOptions look native
  ${NativeUtils.protectFunction(
    'Intl.DateTimeFormat.prototype',
    'resolvedOptions',
    '''
function() {
  const options = OriginalDateTimeFormat.prototype.resolvedOptions.call(this);
  options.timeZone = spoofedTimezone;
  return options;
}
'''
  )}
  
  // Override Date.prototype.getTimezoneOffset
  const originalGetTimezoneOffset = Date.prototype.getTimezoneOffset;
  
  ${NativeUtils.protectFunction(
    'Date.prototype',
    'getTimezoneOffset',
    '''
function() {
  // Calculate offset based on spoofed timezone
  // This is a simplified version - in production, use proper timezone offset calculation
  const spoofedDate = new Date(this.toLocaleString('en-US', { timeZone: spoofedTimezone }));
  const realDate = new Date(this.toLocaleString('en-US', { timeZone: 'UTC' }));
  return (realDate - spoofedDate) / 60000; // Return offset in minutes
}
'''
  )}
  
  // Override toLocaleString to use spoofed timezone
  const originalToLocaleString = Date.prototype.toLocaleString;
  
  ${NativeUtils.protectFunction(
    'Date.prototype',
    'toLocaleString',
    '''
function(locales, options) {
  if (!options) options = {};
  if (!options.timeZone) {
    options.timeZone = spoofedTimezone;
  }
  return originalToLocaleString.call(this, locales, options);
}
'''
  )}
  
  // ===== GEOLOCATION SPOOFING =====
  
  if (navigator.geolocation) {
    const originalGetCurrentPosition = navigator.geolocation.getCurrentPosition;
    const originalWatchPosition = navigator.geolocation.watchPosition;
    
    // Create spoofed position object
    function createPosition() {
      return {
        coords: {
          latitude: spoofedLatitude,
          longitude: spoofedLongitude,
          accuracy: spoofedAccuracy,
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null
        },
        timestamp: Date.now()
      };
    }
    
    // Override getCurrentPosition
    ${NativeUtils.protectFunction(
      'navigator.geolocation',
      'getCurrentPosition',
      '''
function(successCallback, errorCallback, options) {
  if (spoofedLatitude === 0 && spoofedLongitude === 0) {
    // If no geolocation configured, use original
    return originalGetCurrentPosition.call(this, successCallback, errorCallback, options);
  }
  
  // Return spoofed position
  setTimeout(() => {
    if (successCallback) {
      successCallback(createPosition());
    }
  }, 0);
}
'''
    )}
    
    // Override watchPosition
    ${NativeUtils.protectFunction(
      'navigator.geolocation',
      'watchPosition',
      '''
function(successCallback, errorCallback, options) {
  if (spoofedLatitude === 0 && spoofedLongitude === 0) {
    return originalWatchPosition.call(this, successCallback, errorCallback, options);
  }
  
  // Return spoofed position immediately and set interval
  const watchId = Math.floor(Math.random() * 10000);
  
  setTimeout(() => {
    if (successCallback) {
      successCallback(createPosition());
    }
  }, 0);
  
  return watchId;
}
'''
    )}
  }
  
  // Prevent timezone detection via performance.timeOrigin
  if (typeof performance !== 'undefined' && performance.timeOrigin) {
    Object.defineProperty(performance, 'timeOrigin', {
      get: function() {
        return Date.now() - performance.now();
      }
    });
  }
  
  ${NativeUtils.preventNavigatorDetection()}
})();
''';
  }
}
