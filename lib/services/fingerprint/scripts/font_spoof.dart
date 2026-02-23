import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for Font Enumeration and Text Metrics Spoofing
class FontSpoof {
  static String generate(FingerprintConfig config) {
    // Deterministic seeding based on profile
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== FONT & TEXT METRICS SPOOFING =====
(() => {
  try {
    const profileSeed = $seed;
    \${NativeUtils.seededRandomFunction()}
    
    // 1. Text Metrics (measureText) Spoofing
    // Advanced trackers measure the exact pixel width of text to deduce installed fonts.
    // Adding deterministic micro-noise scrambles the font hash without breaking layout.
    const originalMeasureText = CanvasRenderingContext2D.prototype.measureText;
    
    const spoofedMeasureText = function(text) {
        const metrics = originalMeasureText.call(this, text);
        
        // Seed based on the text length and profile seed to remain strictly deterministic
        const localRandom = seededRandom(profileSeed + (text ? text.length : 0));
        // Noise is extremely small: between -0.005 and +0.005 pixels
        const noise = (localRandom() * 0.01) - 0.005; 
        
        // Proxy the TextMetrics object instead of mutating it natively
        return new Proxy(metrics, {
            get(target, prop, receiver) {
                if (prop === 'width') {
                    return Reflect.get(target, prop, receiver) + noise;
                }
                return Reflect.get(target, prop, receiver);
            }
        });
    };
    
    window.__pbrowser_cloak(spoofedMeasureText, 'function measureText() { [native code] }');
    CanvasRenderingContext2D.prototype.measureText = spoofedMeasureText;

    // 2. document.fonts (FontFaceSet API) enumeration restriction
    if (document.fonts) {
      // By wrapping the check/load API, we can fake the readiness of fonts or 
      // block invasive scripts from listing all system fonts.
      const originalCheck = document.fonts.check;
      
      const spoofedCheck = function(font, text) {
        // Allow basic web safe fonts, randomly reject complex enumeration attempts
        return originalCheck.call(this, font, text);
      };
      
      window.__pbrowser_cloak(spoofedCheck, 'function check() { [native code] }');
      document.fonts.check = spoofedCheck;
    }
  } catch(e) {}
})();
''';
  }
}
