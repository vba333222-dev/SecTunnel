import 'package:SecTunnel/models/fingerprint_config.dart';
import 'package:SecTunnel/services/fingerprint/scripts/utils.dart';
import 'package:SecTunnel/utils/security_obfuscator.dart';

/// JavaScript code generator for canvas fingerprint spoofing via noise injection
/// CRITICAL: Uses deterministic seeding based on Profile ID for consistency
class CanvasSpoof {
  static String generate(FingerprintConfig config) {
    // Use canvas noise salt as deterministic seed
    // This ensures same profile always produces same canvas fingerprint
    final seed = config.canvasNoiseSalt.hashCode;
    
    final encrypted = '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';
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('\$seed', seed.toString())
        .replaceAll('__SEEDED_RANDOM__', NativeUtils.seededRandomFunction())
        .replaceAll('__PROTECT_TO_DATA_URL__', NativeUtils.protectFunction(
          'HTMLCanvasElement.prototype',
          'toDataURL',
          '''
function(...args) {
  // Only apply to 2D contexts (not WebGL)
  const context = this.getContext('2d');
  
  if (context && this.width > 0 && this.height > 0) {
    try {
      // Get image data
      const imageData = context.getImageData(0, 0, this.width, this.height);
      
      // Add deterministic noise
      addNoiseToImageData(imageData, 0);
      
      // Put modified data back
      context.putImageData(imageData, 0, 0);
    } catch (e) {
      // Silently fail (e.g., tainted canvas)
    }
  }
  
  return originalToDataURL.apply(this, args);
}
'''
        ))
        .replaceAll('__PROTECT_TO_BLOB__', NativeUtils.protectFunction(
          'HTMLCanvasElement.prototype',
          'toBlob',
          '''
function(callback, ...args) {
  const context = this.getContext('2d');
  
  if (context && this.width > 0 && this.height > 0) {
    try {
      const imageData = context.getImageData(0, 0, this.width, this.height);
      addNoiseToImageData(imageData, 1);
      context.putImageData(imageData, 0, 0);
    } catch (e) {
      // Silently fail
    }
  }
  
  return originalToBlob.call(this, callback, ...args);
}
'''
        ))
        .replaceAll('__PROTECT_GET_IMAGE_DATA__', NativeUtils.protectFunction(
          'CanvasRenderingContext2D.prototype',
          'getImageData',
          '''
function(...args) {
  const imageData = originalGetImageData.apply(this, args);
  return addNoiseToImageData(imageData, 2);
}
'''
        ));
  }
}
