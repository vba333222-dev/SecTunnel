class ProbeDetector {
  static String getJS() {
    return '''
      window.ProbeDetector = (function() {
        const callHistory = new Map();
        const PROBE_THRESHOLD = 20; // max calls
        const PROBE_WINDOW = 1000; // ms
        
        return {
          analyzeCall: function(apiName) {
            const now = performance.now();
            if (!callHistory.has(apiName)) {
              callHistory.set(apiName, []);
            }
            const timestamps = callHistory.get(apiName);
            timestamps.push(now);
            
            // Clean old
            while (timestamps.length > 0 && now - timestamps[0] > PROBE_WINDOW) {
              timestamps.shift();
            }
            
            if (timestamps.length > PROBE_THRESHOLD) {
              if (window.console && window.console.debug) {
                 // console.debug("[ADVERSARIAL] Probe detected on " + apiName);
              }
              return true;
            }
            return false;
          },
          
          getLoadFactor: function() {
            let totalCalls = 0;
            const now = performance.now();
            for (let [api, timestamps] of callHistory) {
              while (timestamps.length > 0 && now - timestamps[0] > PROBE_WINDOW) {
                timestamps.shift();
              }
              totalCalls += timestamps.length;
            }
            return Math.min(2.0, 1.0 + (totalCalls / 50.0));
          }
        };
      })();
    ''';
  }
}
