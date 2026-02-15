import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for canvas fingerprint spoofing via noise injection
class CanvasSpoof {
  static String generate(FingerprintConfig config) {
    // Use canvas noise salt as seed
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== CANVAS NOISE INJECTION =====
(() => {
  const noiseSeed = $seed;
  
  // Seeded pseudo-random number generator
  function seededRandom(seed) {
    const x = Math.sin(seed) * 10000;
    return x - Math.floor(x);
  }
  
  // Store original functions
  const originalToDataURL = HTMLCanvasElement.prototype.toDataURL;
  const originalToBlob = HTMLCanvasElement.prototype.toBlob;
  const originalGetImageData = CanvasRenderingContext2D.prototype.getImageData;
  
  // Inject noise into image data
  function addNoiseToImageData(imageData, salt) {
    const data = imageData.data;
    
    // Add consistent noise based on seed and position
    for (let i = 0; i < data.length; i += 4) {
      const random = seededRandom(salt + i);
      const noise = Math.floor(random * 5) - 2; // Range: -2 to +2
      
      // Apply noise to RGB channels (not alpha)
      data[i] = Math.max(0, Math.min(255, data[i] + noise));       // R
      data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + noise)); // G
      data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + noise)); // B
      // data[i + 3] is alpha, leave untouched
    }
    
    return imageData;
  }
  
  // Override toDataURL
  HTMLCanvasElement.prototype.toDataURL = function(...args) {
    // Only apply to 2D contexts (not WebGL)
    const context = this.getContext('2d');
    
    if (context && this.width > 0 && this.height > 0) {
      try {
        // Get image data
        const imageData = context.getImageData(0, 0, this.width, this.height);
        
        // Add noise
        addNoiseToImageData(imageData, noiseSeed);
        
        // Put modified data back
        context.putImageData(imageData, 0, 0);
      } catch (e) {
        // Silently fail (e.g., tainted canvas)
      }
    }
    
    return originalToDataURL.apply(this, args);
  };
  
  // Override toBlob
  HTMLCanvasElement.prototype.toBlob = function(callback, ...args) {
    const context = this.getContext('2d');
    
    if (context && this.width > 0 && this.height > 0) {
      try {
        const imageData = context.getImageData(0, 0, this.width, this.height);
        addNoiseToImageData(imageData, noiseSeed);
        context.putImageData(imageData, 0, 0);
      } catch (e) {
        // Silently fail
      }
    }
    
    return originalToBlob.call(this, callback, ...args);
  };
  
  // Override getImageData
  CanvasRenderingContext2D.prototype.getImageData = function(...args) {
    const imageData = originalGetImageData.apply(this, args);
    return addNoiseToImageData(imageData, noiseSeed);
  };
})();
''';
  }
}
