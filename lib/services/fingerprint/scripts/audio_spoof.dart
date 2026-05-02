import 'package:SecTunnel/models/fingerprint_config.dart';

class AudioSpoof {
  static String generate(FingerprintConfig config) {
    return '''
      // 5. AUDIO IMPERFECTION
      (function() {
        const AudioContextCtor = window.AudioContext || window.webkitAudioContext;
        if (!AudioContextCtor) return;

        const originalCreateOscillator = AudioContextCtor.prototype.createOscillator;
        const originalCreateDynamicsCompressor = AudioContextCtor.prototype.createDynamicsCompressor;

        if (originalCreateDynamicsCompressor) {
          EmulationEngine.patchMethod(AudioContextCtor.prototype, 'createDynamicsCompressor', function(...args) {
            const compressor = originalCreateDynamicsCompressor.apply(this, args);
            try {
              const thresholdVar = _imperfectionNoise(compressor.threshold.value, _audioSeed ^ 1, 0.0001);
              const ratioVar = _imperfectionNoise(compressor.ratio.value, _audioSeed ^ 2, 0.0001);
              compressor.threshold.value = thresholdVar;
              compressor.ratio.value = ratioVar;
            } catch(e) {}
            return compressor;
          });
        }
        
        if (originalCreateOscillator) {
          EmulationEngine.patchMethod(AudioContextCtor.prototype, 'createOscillator', function(...args) {
            const oscillator = originalCreateOscillator.apply(this, args);
            try {
               const detuneVar = _imperfectionNoise(oscillator.detune.value, _audioSeed ^ 3, 0.0001);
               oscillator.detune.value = detuneVar;
            } catch(e) {}
            return oscillator;
          });
        }
      })();
''';
  }
}
