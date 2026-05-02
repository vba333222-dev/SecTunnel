class PatternBreaker {
  static String getJS() {
    return '''
      window.PatternBreaker = (function() {
        if (!window.IdentityCore) return null;
        
        const baseSeed = window.IdentityCore.getSeed();
        
        const _hash = function(str) {
          let h = 0x811c9dc5;
          for (let i = 0; i < str.length; i++) {
            h ^= str.charCodeAt(i);
            h = (h * 0x01000193) >>> 0;
          }
          return h;
        };

        // Entropy Window Model
        // Seed changes based on time segments to prevent static pattern detection
        const getWindowedSeed = function(t, segmentMs = 60000) {
          const windowId = Math.floor(t / segmentMs);
          return _hash(baseSeed.toString() + windowId.toString());
        };
        
        // Multi-Sampling Resistance
        let callHistory = {};
        
        const simulateProbingResistance = function(apiName) {
           const t = performance.now();
           if (!callHistory[apiName]) {
             callHistory[apiName] = { count: 0, lastCall: t };
           }
           
           const history = callHistory[apiName];
           const diff = t - history.lastCall;
           
           history.lastCall = t;
           
           // Aggressive probing detected (e.g. >10 calls within 10ms)
           if (diff < 10) {
              history.count++;
           } else {
              history.count = Math.max(0, history.count - 1);
           }
           
           if (history.count > 10) {
              // Introduce slight timing variation
              const seed = getWindowedSeed(t, 1000);
              const r = ((seed % 1000) / 1000.0);
              // micro delay to break patterns without crashing
              const end = performance.now() + (r * 2); 
              while(performance.now() < end) {}
           }
        };

        if (window.console && window.console.debug) {
           // console.debug("[ANTI-PROFILE] Pattern breaker active");
           // console.debug("[ANTI-PROFILE] Multi-sample defense active");
        }

        return {
          getWindowedSeed: getWindowedSeed,
          simulateProbingResistance: simulateProbingResistance
        };
      })();
    ''';
  }
}
