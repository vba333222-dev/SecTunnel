class StressHandler {
  static String getJS() {
    return '''
      window.StressHandler = (function() {
        return {
          applyStressDelay: function(baseFn, loadFactor) {
            // If loadFactor is > 1.0, we simulate stress
            if (loadFactor > 1.2) {
               if (window.console && window.console.debug) {
                 // console.debug("[RESILIENCE] Stress handling active");
               }
               const delay = (loadFactor - 1.0) * 2.0; // 0.4ms to 2ms delay
               const end = performance.now() + delay;
               while(performance.now() < end) {}
            }
            return baseFn();
          }
        };
      })();
    ''';
  }
}
