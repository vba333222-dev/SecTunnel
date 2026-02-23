import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for DOMRect / ClientRect Fingerprinting Spoofing
/// Injects deterministic sub-pixel noise to measurements to hide native OS rendering footprints.
class DOMRectSpoof {
  static String generate(FingerprintConfig config) {
    // Deterministic seed based on canvas noise salt
    final seed = config.canvasNoiseSalt.hashCode;

    return '''
// ===== DOMRECT / CLIENTRECT SPOOFING =====
(() => {
  const profileSeed = $seed;

  // Simple deterministic pseudo-random generator based on seed + string content
  const stringHash = (str) => {
    let hash = profileSeed;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32bit integer
    }
    return hash;
  };

  // Generates a micro noise between -0.001 and +0.001 based on element properties
  const getMicroNoise = (element, propertyIndex) => {
     let contentTag = element.tagName || 'UKN';
     if (element.textContent && element.textContent.length > 0) {
         contentTag += element.textContent.substring(0, 50); // Hash first 50 chars of content
     } else if (element.className) {
         contentTag += element.className;
     }
     
     // Generate deterministic noise specific to this element and property
     const hash = stringHash(contentTag + propertyIndex);
     // Normalize hash to a float between -0.001 and 0.001
     const normalized = (Math.abs(hash) % 2000) / 1000000; 
     return normalized - 0.001;
  };

  // --- Spoof getBoundingClientRect ---
  const originalGetBoundingClientRect = Element.prototype.getBoundingClientRect;
  
  // Pick up font-metric deltas published by FontMetricsSpoof (C-5 audit fix)
  const _fwd = () => window.__pbr_wdelta || 0;
  const _fhd = () => window.__pbr_hdelta || 0;

  const spoofedGetBoundingClientRect = function() {
    const rect = originalGetBoundingClientRect.apply(this, arguments);
    
    const noiseTop    = getMicroNoise(this, 1);
    const noiseLeft   = getMicroNoise(this, 2);
    const noiseRight  = getMicroNoise(this, 3);
    const noiseBottom = getMicroNoise(this, 4);
    const fwd = rect.width  === 0 ? 0 : _fwd();
    const fhd = rect.height === 0 ? 0 : _fhd();

    return {
      top:    rect.top    === 0 ? 0 : rect.top    + noiseTop,
      left:   rect.left   === 0 ? 0 : rect.left   + noiseLeft,
      right:  rect.right  === 0 ? 0 : rect.right  + noiseRight + fwd,
      bottom: rect.bottom === 0 ? 0 : rect.bottom + noiseBottom + fhd,
      width:  rect.width  === 0 ? 0 : rect.width  + (noiseRight - noiseLeft) + fwd,
      height: rect.height === 0 ? 0 : rect.height + (noiseBottom - noiseTop) + fhd,
      x: rect.x === 0 ? 0 : rect.x + noiseLeft,
      y: rect.y === 0 ? 0 : rect.y + noiseTop,
      toJSON: () => rect.toJSON ? rect.toJSON() : JSON.stringify(this)
    };
  };

  window.__pbrowser_cloak(spoofedGetBoundingClientRect, 'function getBoundingClientRect() { [native code] }');
  Element.prototype.getBoundingClientRect = spoofedGetBoundingClientRect;


  // --- Spoof getClientRects ---
  const originalGetClientRects = Element.prototype.getClientRects;

  const spoofedGetClientRects = function() {
    const rects = originalGetClientRects.apply(this, arguments);
    const result = [];
    
    for (let i = 0; i < rects.length; i++) {
        const rect = rects[i];
        const noiseTop = getMicroNoise(this, i + 10);
        const noiseLeft = getMicroNoise(this, i + 20);
        const noiseRight = getMicroNoise(this, i + 30);
        const noiseBottom = getMicroNoise(this, i + 40);

        result.push({
          top: rect.top === 0 ? 0 : rect.top + noiseTop,
          left: rect.left === 0 ? 0 : rect.left + noiseLeft,
          right: rect.right === 0 ? 0 : rect.right + noiseRight,
          bottom: rect.bottom === 0 ? 0 : rect.bottom + noiseBottom,
          width: rect.width === 0 ? 0 : rect.width + (noiseRight - noiseLeft),
          height: rect.height === 0 ? 0 : rect.height + (noiseBottom - noiseTop),
          x: rect.x === 0 ? 0 : rect.x + noiseLeft,
          y: rect.y === 0 ? 0 : rect.y + noiseTop,
          toJSON: () => rect.toJSON ? rect.toJSON() : JSON.stringify(this)
        });
    }
    
    // Add item method to match DOMRectList interface
    result.item = function(index) {
        return this[index];
    };
    
    window.__pbrowser_cloak(result.item, 'function item() { [native code] }');

    return result;
  };

  window.__pbrowser_cloak(spoofedGetClientRects, 'function getClientRects() { [native code] }');
  Element.prototype.getClientRects = spoofedGetClientRects;

})();
''';
  }
}
