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
  
  // ===== OFFSCREEN CANVAS SPOOFING =====
  // Advanced trackers use OffscreenCanvas in Web Workers to quietly fingerprint.
  if (typeof OffscreenCanvas !== 'undefined' && typeof OffscreenCanvasRenderingContext2D !== 'undefined') {
    const originalOffscreenConvertToBlob = OffscreenCanvas.prototype.convertToBlob;
    const originalOffscreenGetImageData = OffscreenCanvasRenderingContext2D.prototype.getImageData;

    if (originalOffscreenConvertToBlob) {
      ${NativeUtils.protectFunction(
        'OffscreenCanvas.prototype',
        'convertToBlob',
        '''
function(options) {
  try {
    const ctx = this.getContext('2d');
    if (ctx && this.width > 0 && this.height > 0) {
      const imageData = ctx.getImageData(0, 0, this.width, this.height);
      addNoiseToImageData(imageData, 3);
      ctx.putImageData(imageData, 0, 0);
    }
  } catch(e) {}
  return originalOffscreenConvertToBlob.call(this, options);
}
'''
      )}
    }

    if (originalOffscreenGetImageData) {
      ${NativeUtils.protectFunction(
        'OffscreenCanvasRenderingContext2D.prototype',
        'getImageData',
        '''
function(...args) {
  const imageData = originalOffscreenGetImageData.apply(this, args);
  return addNoiseToImageData(imageData, 4);
}
'''
      )}
    }
  }
  
  // ===== CANVAS TEXT SUB-PIXEL RENDERING CORRUPTION =====
  // Intercept fillText/strokeText to apply micro-shadow before draw.
  // The shadow shifts the sub-pixel alpha compositing sequence, destroying
  // FreeType's characteristic blending signature without visible effect.
  (() => {
    try {
      const originalFillText   = CanvasRenderingContext2D.prototype.fillText;
      const originalStrokeText = CanvasRenderingContext2D.prototype.strokeText;

      // Deterministic micro-offsets from profile seed
      const shadowX = ((profileSeed & 0xFF) / 0xFF) * 0.05 - 0.025; // -0.025 to +0.025 px
      const shadowY = (((profileSeed >> 8) & 0xFF) / 0xFF) * 0.05 - 0.025;
      const shadowAlpha = 0.004 + ((profileSeed & 0xF) / 0xF) * 0.006; // 0.004–0.010 opacity

      // Apply ghost shadow overlay before the real draw, then restore context state
      const withShadow = (ctx, drawFn) => {
        const prevShadowColor   = ctx.shadowColor;
        const prevShadowBlur    = ctx.shadowBlur;
        const prevShadowOffsetX = ctx.shadowOffsetX;
        const prevShadowOffsetY = ctx.shadowOffsetY;
        const prevAlpha         = ctx.globalAlpha;
        const prevComposite     = ctx.globalCompositeOperation;

        // Inject imperceptible shadow — disrupts sub-pixel anti-aliasing compositing
        ctx.shadowColor   = `rgba(0,0,0,\${shadowAlpha})`;
        ctx.shadowBlur    = 0;
        ctx.shadowOffsetX = shadowX;
        ctx.shadowOffsetY = shadowY;

        drawFn();

        // Restore original state
        ctx.shadowColor           = prevShadowColor;
        ctx.shadowBlur            = prevShadowBlur;
        ctx.shadowOffsetX         = prevShadowOffsetX;
        ctx.shadowOffsetY         = prevShadowOffsetY;
        ctx.globalAlpha           = prevAlpha;
        ctx.globalCompositeOperation = prevComposite;
      };

      const spoofedFillText = function(text, x, y, maxWidth) {
        withShadow(this, () => {
          maxWidth !== undefined
            ? originalFillText.call(this, text, x, y, maxWidth)
            : originalFillText.call(this, text, x, y);
        });
      };

      const spoofedStrokeText = function(text, x, y, maxWidth) {
        withShadow(this, () => {
          maxWidth !== undefined
            ? originalStrokeText.call(this, text, x, y, maxWidth)
            : originalStrokeText.call(this, text, x, y);
        });
      };

      window.__pbrowser_cloak(spoofedFillText,   'function fillText() { [native code] }');
      window.__pbrowser_cloak(spoofedStrokeText, 'function strokeText() { [native code] }');

      CanvasRenderingContext2D.prototype.fillText   = spoofedFillText;
      CanvasRenderingContext2D.prototype.strokeText = spoofedStrokeText;

      // Also apply to OffscreenCanvasRenderingContext2D if available
      if (typeof OffscreenCanvasRenderingContext2D !== 'undefined') {
        const offSpoofedFillText = function(text, x, y, maxWidth) {
          withShadow(this, () => {
            maxWidth !== undefined
              ? originalFillText.call(this, text, x, y, maxWidth)
              : originalFillText.call(this, text, x, y);
          });
        };

        const offSpoofedStrokeText = function(text, x, y, maxWidth) {
          withShadow(this, () => {
            maxWidth !== undefined
              ? originalStrokeText.call(this, text, x, y, maxWidth)
              : originalStrokeText.call(this, text, x, y);
          });
        };

        window.__pbrowser_cloak(offSpoofedFillText,   'function fillText() { [native code] }');
        window.__pbrowser_cloak(offSpoofedStrokeText, 'function strokeText() { [native code] }');

        OffscreenCanvasRenderingContext2D.prototype.fillText   = offSpoofedFillText;
        OffscreenCanvasRenderingContext2D.prototype.strokeText = offSpoofedStrokeText;
      }

    } catch(e) {}
  })();

})();
''';
  }
}
