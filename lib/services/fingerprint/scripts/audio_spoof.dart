import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for AudioContext fingerprint spoofing
/// CRITICAL: Uses deterministic seeding based on Profile ID for consistency
class AudioSpoof {
  static String generate(FingerprintConfig config) {
    // Use canvas noise salt as deterministic seed
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== AUDIO CONTEXT SPOOFING (DETERMINISTIC & NON-DISRUPTIVE) =====
(() => {
  const profileSeed = $seed;
  
  \${NativeUtils.seededRandomFunction()}
  
  const getRandom = seededRandom(profileSeed);
  
  const OriginalAudioContext = window.AudioContext || window.webkitAudioContext;
  if (!OriginalAudioContext) return;
  
  // Directly intercept the prototype to prevent `audioCtx.constructor !== AudioContext` detection
  const originalCreateAnalyser = OriginalAudioContext.prototype.createAnalyser;

  const spoofedCreateAnalyser = function() {
    const analyser = originalCreateAnalyser.apply(this, arguments);
    
    // Store original methods
    const originalGetFloatFrequencyData = analyser.getFloatFrequencyData.bind(analyser);
    const originalGetByteFrequencyData = analyser.getByteFrequencyData.bind(analyser);
    const originalGetFloatTimeDomainData = analyser.getFloatTimeDomainData.bind(analyser);
    const originalGetByteTimeDomainData = analyser.getByteTimeDomainData.bind(analyser);
    
    // Initialize deterministic noise generator
    const localRandom = seededRandom(profileSeed + 1000);
    
    // Override getFloatFrequencyData
    analyser.getFloatFrequencyData = function(array) {
      originalGetFloatFrequencyData(array);
      for (let i = 0; i < array.length; i++) {
        array[i] += (localRandom() - 0.5) * 0.0001;
      }
    };
    window.__pbrowser_cloak(analyser.getFloatFrequencyData, `function getFloatFrequencyData() { [native code] }`);
    
    // Override getByteFrequencyData
    analyser.getByteFrequencyData = function(array) {
      originalGetByteFrequencyData(array);
      for (let i = 0; i < array.length; i++) {
        const noise = Math.floor((localRandom() - 0.5) * 2);
        array[i] = Math.max(0, Math.min(255, array[i] + noise));
      }
    };
    window.__pbrowser_cloak(analyser.getByteFrequencyData, `function getByteFrequencyData() { [native code] }`);
    
    // Override getFloatTimeDomainData
    analyser.getFloatTimeDomainData = function(array) {
      originalGetFloatTimeDomainData(array);
      for (let i = 0; i < array.length; i++) {
        array[i] += (localRandom() - 0.5) * 0.00001;
      }
    };
    window.__pbrowser_cloak(analyser.getFloatTimeDomainData, `function getFloatTimeDomainData() { [native code] }`);
    
    // Override getByteTimeDomainData
    analyser.getByteTimeDomainData = function(array) {
      originalGetByteTimeDomainData(array);
      for (let i = 0; i < array.length; i++) {
        const noise = Math.floor((localRandom() - 0.5) * 2);
        array[i] = Math.max(0, Math.min(255, array[i] + noise));
      }
    };
    window.__pbrowser_cloak(analyser.getByteTimeDomainData, `function getByteTimeDomainData() { [native code] }`);
    
    return analyser;
  };
  
  // Mask the createAnalyser prototype function to look 100% native
  window.__pbrowser_cloak(spoofedCreateAnalyser, `function createAnalyser() { [native code] }`);
  
  // Apply our cloaked function back to the exact prototype chain
  OriginalAudioContext.prototype.createAnalyser = spoofedCreateAnalyser;

})();
''';
  }
}

