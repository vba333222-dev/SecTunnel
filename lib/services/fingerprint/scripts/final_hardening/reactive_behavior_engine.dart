class ReactiveBehaviorEngine {
  static String getJS() {
    return '''
      window.ReactiveBehaviorEngine = (function() {
        let eventHistory = [];
        let state = 'idle';
        let lastEventTime = performance.now();
        
        const updateHistory = function(t) {
          eventHistory.push(t);
          if (eventHistory.length > 50) eventHistory.shift();
          
          const timeSinceLast = t - lastEventTime;
          lastEventTime = t;
          
          // State transition
          let newState = state;
          if (timeSinceLast > 3000) newState = 'idle';
          else if (timeSinceLast < 100 && eventHistory.length >= 10 && (t - eventHistory[eventHistory.length-10] < 1000)) newState = 'burst';
          else newState = 'active';
          
          let stateSpike = 0;
          if (state === 'idle' && newState === 'active') {
             // Micro-hesitation model: slight pause before action when switching from idle
             stateSpike = 25; 
          }
          
          state = newState;
          return { state, stateSpike };
        };

        const getAdaptiveLatency = function(t) {
          const { state, stateSpike } = updateHistory(t);
          
          let latency = 0;
          if (state === 'burst') latency = -5; // temporary acceleration
          if (state === 'idle') latency = 15; // cold start
          
          return latency + stateSpike;
        };

        return {
          getAdaptiveLatency: getAdaptiveLatency
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[BEHAVIOR] Reactive engine active");
      }
    ''';
  }
}
