import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for AudioContext fingerprint spoofing
/// CRITICAL: Uses deterministic seeding based on Profile ID for consistency
class AudioSpoof {
  static String generate(FingerprintConfig config) {
    // Use canvas noise salt as deterministic seed
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== AUDIO CONTEXT SPOOFING (DETERMINISTIC) =====
(() => {
  const profileSeed = $seed;
  
  ${NativeUtils.seededRandomFunction()}
  
  // Initialize seeded random generator
  const getRandom = seededRandom(profileSeed);
  
  // Store original AudioContext
  const OriginalAudioContext = window.AudioContext || window.webkitAudioContext;
  
  if (!OriginalAudioContext) return;
  
  // Override AudioContext constructor
  function SpoofedAudioContext(...args) {
    const context = new OriginalAudioContext(...args);
    
    // Store original createAnalyser
    const originalCreateAnalyser = context.createAnalyser.bind(context);
    
    // Override createAnalyser with deterministic noise
    ${NativeUtils.protectFunction(
      'context',
      'createAnalyser',
      '''
function() {
  const analyser = originalCreateAnalyser();
  
  // Store original methods
  const originalGetFloatFrequencyData = analyser.getFloatFrequencyData.bind(analyser);
  const originalGetByteFrequencyData = analyser.getByteFrequencyData.bind(analyser);
  const originalGetFloatTimeDomainData = analyser.getFloatTimeDomainData.bind(analyser);
  const originalGetByteTimeDomainData = analyser.getByteTimeDomainData.bind(analyser);
  
  // Reset random for consistency
  const localRandom = seededRandom(profileSeed + 1000);
  
  // Override getFloatFrequencyData
  analyser.getFloatFrequencyData = function(array) {
    originalGetFloatFrequencyData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = (localRandom() - 0.5) * 0.0001;
      array[i] += noise;
    }
  };
  
  // Override getByteFrequencyData
  analyser.getByteFrequencyData = function(array) {
    originalGetByteFrequencyData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = Math.floor((localRandom() - 0.5) * 2);
      array[i] = Math.max(0, Math.min(255, array[i] + noise));
    }
  };
  
  // Override getFloatTimeDomainData
  analyser.getFloatTimeDomainData = function(array) {
    originalGetFloatTimeDomainData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = (localRandom() - 0.5) * 0.00001;
      array[i] += noise;
    }
  };
  
  // Override getByteTimeDomainData
  analyser.getByteTimeDomainData = function(array) {
    originalGetByteTimeDomainData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = Math.floor((localRandom() - 0.5) * 2);
      array[i] = Math.max(0, Math.min(255, array[i] + noise));
    }
  };
  
  return analyser;
}
'''
    )}
    
    return context;
  }
  
  // Copy properties from original constructor
  SpoofedAudioContext.prototype = OriginalAudioContext.prototype;
  
  // Make constructor look native
  Object.defineProperty(SpoofedAudioContext, 'toString', {
    value: function() {
      return OriginalAudioContext.toString();
    }
  });
  
  // Replace global AudioContext
  window.AudioContext = SpoofedAudioContext;
  if (window.webkitAudioContext) {
    window.webkitAudioContext = SpoofedAudioContext;
  }
})();
''';
  }
}
