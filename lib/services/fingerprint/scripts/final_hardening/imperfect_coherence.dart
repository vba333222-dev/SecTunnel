class ImperfectCoherence {
  static String getJS() {
    return '''
      window.ImperfectCoherence = (function() {
        if (!window.IdentityCore || !window.ChaoticNoiseEngine) return null;
        
        const persona = window.IdentityCore.getPersona();
        const baseSeed = window.IdentityCore.getSeed();
        const chaos = window.ChaoticNoiseEngine;
        
        // Add 1-2% deviation between layers
        return {
          getTimingDesync: function(t) {
            const val = chaos.boundedChaos(t, baseSeed + 1);
            if (Math.abs(val) > 1.5) {
               // Rare desync: pretend device is slightly slower than it is for a moment
               return persona.cpuTier === 'high' ? 15 : 30; 
            }
            return 0;
          },
          
          getRenderingDesync: function(t) {
            const val = chaos.boundedChaos(t, baseSeed + 2);
            if (Math.abs(val) > 1.8) {
               // Rare frame drop or slight render anomaly
               return val * 0.1;
            }
            return 0;
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[COHERENCE] Imperfect sync active");
      }
    ''';
  }
}
