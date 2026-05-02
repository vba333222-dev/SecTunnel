class ChaoticNoiseEngine {
  static String getJS() {
    return '''
      window.ChaoticNoiseEngine = (function() {
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

        return {
          chaoticNoise: function(input, seed) {
            // Pseudo-chaotic function using logistic map approximation + xorshift
            // Not smooth, not symmetric
            let state = _hash(seed.toString() + input.toString());
            let r = (_xorshift(state) % 10000) / 10000.0;
            
            // Logistic map r=3.9
            let x = r;
            for(let i=0; i<3; i++) {
               x = 3.9 * x * (1 - x);
            }
            
            // Transform to [-1, 1] range, slightly skewed
            return (x * 2.1) - 1.0;
          },

          boundedChaos: function(input, seed) {
            let state = _hash(seed.toString() + "bounded" + input.toString());
            let r = (_xorshift(state) % 10000) / 10000.0;
            
            // 97% normal, 3% micro-chaos deviation
            if (r > 0.97) {
              return this.chaoticNoise(input, state) * 2.0; // small spike
            }
            
            // Add independent, non-correlated tiny noise layer
            return (r - 0.5) * 0.05; 
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[CHAOS] Chaotic layer active");
      }
    ''';
  }
}
