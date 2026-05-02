class DistributionDistorter {
  static String getJS() {
    return '''
      window.DistributionDistorter = (function() {
        if (!window.IdentityCore) return null;
        const baseSeed = window.IdentityCore.getSeed();

        const _hash = function(str) {
          let h = 0x811c9dc5;
          for (let i = 0; i < str.length; i++) h ^= str.charCodeAt(i);
          return (h * 0x01000193) >>> 0;
        };

        // Windowed Entropy Variation
        let currentWindowId = -1;
        let windowedSeed = baseSeed;
        
        const updateWindow = function(t) {
          const windowId = Math.floor(t / 45000); // 45 sec windows
          if (windowId !== currentWindowId) {
             currentWindowId = windowId;
             windowedSeed = _hash(baseSeed.toString() + windowId.toString());
          }
        };

        return {
          distort: function(val, t) {
            updateWindow(t);
            const state = _hash(windowedSeed.toString() + t.toString());
            const r = (state % 100) / 100.0;
            
            // Break symmetry: use skewed distribution (x^3)
            let skew = Math.pow(r, 3);
            
            // Clustered intervals
            let cluster = Math.floor(skew * 10) / 10;
            
            return val * (1 + (cluster - 0.5) * 0.1);
          },
          
          getWindowSeed: function(t) {
            updateWindow(t);
            return windowedSeed;
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[ANTI-PATTERN] Distribution distortion active");
      }
    ''';
  }
}
