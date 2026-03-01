import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';
import 'package:pbrowser/utils/security_obfuscator.dart';

/// JavaScript code generator for timezone and geolocation spoofing
/// CRITICAL: Synchronizes timezone with proxy IP location for consistency
class TimezoneSpoof {
  static String generate(FingerprintConfig config) {
    final timezone = NativeUtils.escapeJs(config.timezone);
    final latitude = config.geolocation?.latitude ?? 0.0;
    final longitude = config.geolocation?.longitude ?? 0.0;
    final accuracy = config.geolocation?.accuracy ?? 50.0;
    
    final encrypted = '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';
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('\$timezone', timezone)
        .replaceAll('\$latitude', latitude.toString())
        .replaceAll('\$longitude', longitude.toString())
        .replaceAll('\$accuracy', accuracy.toString())
        .replaceAll('__PROTECT_RESOLVED_OPTIONS__', NativeUtils.protectFunction(
          'Intl.DateTimeFormat.prototype',
          'resolvedOptions',
          '''
function() {
  const options = OriginalDateTimeFormat.prototype.resolvedOptions.call(this);
  options.timeZone = spoofedTimezone;
  return options;
}
'''
        ))
        .replaceAll('__PROTECT_GET_TIMEZONE_OFFSET__', NativeUtils.protectFunction(
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
        ))
        .replaceAll('__PROTECT_TO_LOCALE_STRING__', NativeUtils.protectFunction(
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
        ))
        .replaceAll('__PROTECT_GET_CURRENT_POSITION__', NativeUtils.protectFunction(
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
        ))
        .replaceAll('__PROTECT_WATCH_POSITION__', NativeUtils.protectFunction(
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
        ))
        .replaceAll('__PREVENT_NAV_DETECTION__', NativeUtils.preventNavigatorDetection());
  }
}
