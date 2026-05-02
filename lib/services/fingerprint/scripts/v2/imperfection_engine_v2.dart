class ImperfectionEngineV2 {
  static String getJS() {
    return '''
      window.ImperfectionEngineV2 = (function() {
        const _hash = function(str) {
          let h = 0x811c9dc5;
          for (let i = 0; i < str.length; i++) {
            h ^= str.charCodeAt(i);
            h = (h * 0x01000193) >>> 0;
          }
          return h;
        };

        const _xorshift = function(state) {
          let x = state;
          x ^= x << 13;
          x ^= x >>> 17;
          x ^= x << 5;
          return x >>> 0;
        };

        const _piecewise = function(val) {
          if (val < 0.2) return val * 1.5;
          if (val < 0.8) return 0.3 + (val - 0.2) * 0.5;
          return 0.6 + (val - 0.8) * 2.0;
        };

        return {
          deriveSeed: function(baseSeed, contextKey) {
            return _hash(baseSeed.toString() + contextKey);
          },

          irregularNoise: function(input, seed) {
            let state = _hash(seed.toString() + input.toString());
            let r1 = (_xorshift(state) % 10000) / 10000.0;
            state = _xorshift(state);
            let r2 = (_xorshift(state) % 10000) / 10000.0;
            
            // Curve-based non-symmetric noise
            let noise = _piecewise(r1) - _piecewise(r2) * 0.7;
            return noise;
          },

          microSpike: function(input, seed) {
            let state = _hash(seed.toString() + "spike" + input.toString());
            let r = (_xorshift(state) % 10000) / 10000.0;
            
            // 95% normal, 5% slight anomaly
            if (r > 0.95) {
               return (r - 0.95) * 10; // small spike up to 0.5
            }
            return 0;
          },

          drift: function(time, seed) {
            // Slow time-dependent drift, bounded and non-linear
            let state = _hash(seed.toString() + "drift");
            let r = (_xorshift(state) % 10000) / 10000.0;
            
            // drift uses a bounded non-linear function
            // Math.sin is smooth, so we combine it with irregular steps
            let base = Math.sin(time / 10000) * 0.5 + Math.cos(time / 23000) * 0.3;
            let step = Math.floor(time / 5000) % 7;
            let irregular = (step / 7) * 0.2;
            
            return (base + irregular) * r;
          }
        };
      })();
      
      if (window.console && window.console.debug) {
         // console.debug("[IMPERFECTION_V2] Non-linear noise active");
      }
    ''';
  }
}
