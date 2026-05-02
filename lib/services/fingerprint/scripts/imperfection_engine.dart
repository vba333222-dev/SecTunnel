class ImperfectionEngine {
  static String generate(int sessionSeed) {
    return '''
      // 1. GLOBAL ENTROPY MODEL
      const _sessionSeed = $sessionSeed;
      
      function _xorshift32(state) {
        state ^= state << 13;
        state ^= state >> 17;
        state ^= state << 5;
        return state >>> 0;
      }
      
      function _deriveSeed(domain) {
        let h = _sessionSeed ^ 0x811C9DC5;
        for (let i = 0; i < domain.length; i++) {
          h ^= domain.charCodeAt(i);
          h = Math.imul(h, 0x01000193);
        }
        return h >>> 0;
      }

      const _canvasSeed = _deriveSeed("canvas");
      const _webglSeed = _deriveSeed("webgl");
      const _timingSeed = _deriveSeed("timing");
      const _audioSeed = _deriveSeed("audio");

      // 2. IMPERFECTION ENGINE CORE
      function _imperfectionNoise(base, seed, factor) {
        let s = _xorshift32(seed ^ Math.round(Math.abs(base) * 100000));
        let norm = (s / 4294967296) * 2 - 1; 
        return base + (norm * factor);
      }

      function _imperfectionMicroJitter(base, seed) {
        let s = _xorshift32(seed ^ Math.round(Math.abs(base) * 10000));
        let norm = (s / 4294967296);
        return base + (Math.sin(norm * Math.PI) * 0.00001);
      }

      function _imperfectionTimeDrift(time, seed) {
        let driftAmplitude = ((seed % 100) / 100) * 1.5; 
        let period = 60000 * 5; 
        let phase = (seed % 10000) / 10000 * Math.PI * 2;
        return time + Math.sin((time / period) * Math.PI * 2 + phase) * driftAmplitude;
      }
      
      console.debug("[IMPERFECTION] Engine initialized");
      console.debug("[IMPERFECTION] Seed applied");
      console.debug("[IMPERFECTION] Modules correlated");
''';
  }
}
