class SystemRhythm {
  static String getJS() {
    return '''
      window.SystemRhythm = (function() {
        const startTime = performance.now();
        
        // Simulates thermal-like effect and long-range rhythm
        return {
          getRhythmFactor: function(t) {
            const sessionDuration = t - startTime;
            
            // Thermal simulation: prolonged usage -> slight slowdown
            // Scales up slowly over 30 minutes, maxing at 1.1x multiplier
            const thermal = Math.min(1.1, 1.0 + (sessionDuration / (30 * 60 * 1000)) * 0.1);
            
            // Burst vs Slow periods (irregular cycles)
            // Combine prime number frequencies to avoid perfect periodicity
            const burst = Math.sin(t / 13000) * Math.sin(t / 17000) * Math.cos(t / 23000);
            
            // If burst > 0.5, we are in a slow period
            const slowFactor = burst > 0.5 ? 1.05 : 1.0;
            
            return thermal * slowFactor;
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[RHYTHM] System rhythm active");
      }
    ''';
  }
}
