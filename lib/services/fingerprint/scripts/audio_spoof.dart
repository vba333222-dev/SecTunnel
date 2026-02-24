import 'package:pbrowser/models/fingerprint_config.dart';

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

  // M-4 FIX: Spoof sampleRate — Android WebView defaults to 48000Hz, Desktop is 44100Hz
  // Override via Proxy on the AudioContext constructor so every new context reports 44100
  const _DESKTOP_SAMPLE_RATE = 44100;
  const _origACDescSR = Object.getOwnPropertyDescriptor(AudioContext.prototype, 'sampleRate');
  if (_origACDescSR && _origACDescSR.get) {
    const _origSRGetter = _origACDescSR.get;
    const _spoofedSRGetter = function() {
      const real = _origSRGetter.call(this);
      // Only override if it's the Android 48000Hz default; don't touch if already 44100
      return real === 48000 ? _DESKTOP_SAMPLE_RATE : real;
    };
    window.__pbrowser_cloak(_spoofedSRGetter, 'function get sampleRate() { [native code] }');
    Object.defineProperty(AudioContext.prototype, 'sampleRate', {
      get: _spoofedSRGetter, configurable: true, enumerable: true
    });
  }

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

  // ======================================================
  // OFFLINE AUDIO CONTEXT — startRendering() deep hash evasion
  // ======================================================
  // Intercepts the Promise returned by startRendering() and injects
  // deterministic micro-noise into Float32Array channel data before
  // the fingerprinting script can hash it.
  (() => {
    try {
      const OAC = window.OfflineAudioContext || window.webkitOfflineAudioContext;
      if (!OAC) return;

      const origStartRendering = OAC.prototype.startRendering;

      // Noise generator seeded per-profile (Mulberry32)
      const spoofBuffer = (audioBuffer) => {
        try {
          const channels = audioBuffer.numberOfChannels;
          // Seed advances differently for each channel to ensure distinct perturbations
          for (let c = 0; c < channels; c++) {
            const data = audioBuffer.getChannelData(c); // Float32Array
            const localSeed = profileSeed + c * 0x7FFFF;
            let rng = localSeed;

            // Perturb only ~14 strategically-spaced samples to minimise compute
            // but guarantee hash divergence from native Android DSP output
            const step = Math.max(1, Math.floor(data.length / 14));
            for (let i = 0; i < data.length; i += step) {
              // Mulberry32 step
              rng += 0x6D2B79F5;
              let z = rng;
              z = Math.imul(z ^ z >>> 15, z | 1);
              z ^= z + Math.imul(z ^ z >>> 7, z | 61);
              z ^= z >>> 14;
              const rand = (z >>> 0) / 0xFFFFFFFF; // 0.0 – 1.0
              // Noise amplitude: ±0.0000001 — below human auditory threshold
              data[i] += (rand - 0.5) * 0.0000002;
            }
          }
        } catch(e) {}
        return audioBuffer;
      };

      const spoofedStartRendering = function() {
        const promise = origStartRendering.apply(this, arguments);
        if (promise && typeof promise.then === 'function') {
          return promise.then(spoofBuffer);
        }
        return promise;
      };

      window.__pbrowser_cloak(spoofedStartRendering, 'function startRendering() { [native code] }');
      OAC.prototype.startRendering = spoofedStartRendering;

      // Also intercept the legacy event-based oncomplete path
      // Some older fingerprint scripts listen to ctx.oncomplete instead of the Promise
      const origAddEventListener = OAC.prototype.addEventListener;
      if (origAddEventListener) {
        const patchedAddEventListener = function(type, listener, ...rest) {
          if (type === 'complete') {
            const wrappedListener = function(event) {
              if (event && event.renderedBuffer) {
                spoofBuffer(event.renderedBuffer);
              }
              return listener.apply(this, arguments);
            };
            return origAddEventListener.call(this, type, wrappedListener, ...rest);
          }
          return origAddEventListener.call(this, type, listener, ...rest);
        };
        window.__pbrowser_cloak(patchedAddEventListener, 'function addEventListener() { [native code] }');
        OAC.prototype.addEventListener = patchedAddEventListener;
      }

    } catch(e) {}
  })();

})();
''';
  }
}

