class BackgroundActivity {
  static String getJS() {
    return '''
      window.BackgroundActivity = (function() {
        if (!window.IdentityCore) return null;
        
        let lastWakeup = performance.now();

        return {
          getIdleJitter: function(t) {
            // Minor CPU wakeups during idle
            const timeSinceWakeup = t - lastWakeup;
            if (timeSinceWakeup > 2000) {
               // Pseudo-random wakeup chance
               const r = Math.sin(t * 0.001) * Math.cos(t * 0.003);
               if (r > 0.8) {
                  lastWakeup = t;
                  return 2.0; // 2ms jitter spike
               }
            }
            // Always slight non-zero activity
            return (Math.sin(t * 0.01) * 0.05); 
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[PASSIVE] Background noise active");
      }
    ''';
  }
}
