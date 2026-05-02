class IdentityEvolution {
  static String getJS() {
    return '''
      window.IdentityEvolution = (function() {
        if (!window.IdentityCore) return null;
        
        const baseSeed = window.IdentityCore.getSeed();
        const startTime = performance.now();

        return {
          getFatigueFactor: function() {
            const elapsed = performance.now() - startTime;
            // Fatigue simulation: longer session -> slightly slower response
            // e.g., max 20% slower after 2 hours
            const maxFatigue = 0.20;
            const twoHours = 2 * 60 * 60 * 1000;
            let fatigue = (elapsed / twoHours) * maxFatigue;
            if (fatigue > maxFatigue) fatigue = maxFatigue;
            
            return 1.0 + fatigue;
          },
          
          getDriftOffset: function() {
            const elapsed = performance.now() - startTime;
            // Small subtle timing shift over time
            return Math.sin(elapsed / 300000) * 2.0; 
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[EVOLUTION] Long-session drift active");
      }
    ''';
  }
}
