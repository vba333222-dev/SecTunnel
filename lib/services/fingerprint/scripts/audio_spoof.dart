import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for AudioContext fingerprint spoofing
class AudioSpoof {
  static String generate(FingerprintConfig config) {
    final seed = config.canvasNoiseSalt.hashCode;
    
    return '''
// ===== AUDIO CONTEXT SPOOFING =====
(() => {
  const noiseSeed = $seed;
  
  function seededRandom(seed) {
    const x = Math.sin(seed) * 10000;
    return x - Math.floor(x);
  }
  
  try {
    // Check if AudioContext exists
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    
    const OriginalAnalyser = AudioContext.prototype.createAnalyser;
    
    AudioContext.prototype.createAnalyser = function() {
      const analyser = OriginalAnalyser.apply(this, arguments);
      
      const originalGetFloatFrequencyData = analyser.getFloatFrequencyData;
      const originalGetByteFrequencyData = analyser.getByteFrequencyData;
      const originalGetFloatTimeDomainData = analyser.getFloatTimeDomainData;
      const originalGetByteTimeDomainData = analyser.getByteTimeDomainData;
      
      // Add noise to float frequency data
      analyser.getFloatFrequencyData = function(array) {
        originalGetFloatFrequencyData.apply(this, arguments);
        
        for (let i = 0; i < array.length; i++) {
          const noise = (seededRandom(noiseSeed + i) - 0.5) * 0.0001;
          array[i] += noise;
        }
      };
      
      // Add noise to byte frequency data
      analyser.getByteFrequencyData = function(array) {
        originalGetByteFrequencyData.apply(this, arguments);
        
        for (let i = 0; i < array.length; i++) {
          const noise = Math.floor((seededRandom(noiseSeed + i) - 0.5) * 2);
          array[i] = Math.max(0, Math.min(255, array[i] + noise));
        }
      };
      
      // Add noise to float time domain data
      analyser.getFloatTimeDomainData = function(array) {
        originalGetFloatTimeDomainData.apply(this, arguments);
        
        for (let i = 0; i < array.length; i++) {
          const noise = (seededRandom(noiseSeed + i + 1000) - 0.5) * 0.0001;
          array[i] += noise;
        }
      };
      
      // Add noise to byte time domain data
      analyser.getByteTimeDomainData = function(array) {
        originalGetByteTimeDomainData.apply(this, arguments);
        
        for (let i = 0; i < array.length; i++) {
          const noise = Math.floor((seededRandom(noiseSeed + i + 1000) - 0.5) * 2);
          array[i] = Math.max(0, Math.min(255, array[i] + noise));
        }
      };
      
      return analyser;
    };
  } catch (e) {
    // AudioContext not available or error, skip
  }
})();
''';
  }
}
