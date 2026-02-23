import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for canvas fingerprint spoofing via noise injection
/// CRITICAL: Uses deterministic seeding based on Profile ID for consistency
class CanvasSpoof {
  static String generate(FingerprintConfig config) {
    // Use canvas noise salt as deterministic seed
    // This ensures same profile always produces same canvas fingerprint
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== CANVAS NOISE INJECTION (DETERMINISTIC) =====
(() => {
  const profileSeed = $seed;
  
  ${NativeUtils.seededRandomFunction()}
  
  // Initialize seeded random generator
  const getRandom = seededRandom(profileSeed);
  
  // Inject noise into image data (deterministic)
  function addNoiseToImageData(imageData, iterationOffset = 0) {
    const data = imageData.data;
    
    // Reset random generator for consistency
    const localRandom = seededRandom(profileSeed + iterationOffset);
    
    // Add consistent noise based on seed and position
    for (let i = 0; i < data.length; i += 4) {
      const random = localRandom();
      const noise = Math.floor(random * 5) - 2; // Range: -2 to +2
      
      // Apply noise to RGB channels (not alpha)
      data[i] = Math.max(0, Math.min(255, data[i] + noise));       // R
      data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + noise)); // G
      data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + noise)); // B
      // data[i + 3] is alpha, leave untouched
    }
    
    return imageData;
  }
  
  // Store original functions
  const originalToDataURL = HTMLCanvasElement.prototype.toDataURL;
  const originalToBlob = HTMLCanvasElement.prototype.toBlob;
  const originalGetImageData = CanvasRenderingContext2D.prototype.getImageData;
  
  // Override toDataURL with native cloaking
  ${NativeUtils.protectFunction(
    'HTMLCanvasElement.prototype',
    'toDataURL',
    '''
function(...args) {
  if (this.width > 0 && this.height > 0) {
    try {
      // Use offscreen canvas to avoid mutating visible elements
      const offscreen = document.createElement('canvas');
      offscreen.width = this.width;
      offscreen.height = this.height;
      const ctx = offscreen.getContext('2d');
      ctx.drawImage(this, 0, 0);
      
      // Add deterministic noise
      const imageData = ctx.getImageData(0, 0, this.width, this.height);
      addNoiseToImageData(imageData, 0);
      ctx.putImageData(imageData, 0, 0);
      
      // Return spoofed data
      return originalToDataURL.apply(offscreen, args);
    } catch (e) {
      // Silently fail (e.g., tainted canvas)
    }
  }
  return originalToDataURL.apply(this, args);
}
'''
  )}
  
  // Override toBlob with native cloaking
  ${NativeUtils.protectFunction(
    'HTMLCanvasElement.prototype',
    'toBlob',
    '''
function(callback, ...args) {
  if (this.width > 0 && this.height > 0) {
    try {
      const offscreen = document.createElement('canvas');
      offscreen.width = this.width;
      offscreen.height = this.height;
      const ctx = offscreen.getContext('2d');
      ctx.drawImage(this, 0, 0);
      
      const imageData = ctx.getImageData(0, 0, this.width, this.height);
      addNoiseToImageData(imageData, 1);
      ctx.putImageData(imageData, 0, 0);
      
      return originalToBlob.call(offscreen, callback, ...args);
    } catch (e) {
      // Silently fail
    }
  }
  return originalToBlob.call(this, callback, ...args);
}
'''
  )}
  
  // Override getImageData with native cloaking
  ${NativeUtils.protectFunction(
    'CanvasRenderingContext2D.prototype',
    'getImageData',
    '''
function(...args) {
  const imageData = originalGetImageData.apply(this, args);
  return addNoiseToImageData(imageData, 2);
}
'''
  )}
})();
''';
  }
}
