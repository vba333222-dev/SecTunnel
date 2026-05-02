class EventLatencyPatchV2 {
  static String getJS() {
    return '''
      (function() {
        if (!window.BehaviorProfile || !window.ImperfectionEngineV2) return;
        
        const profile = window.BehaviorProfile;
        const eng = window.ImperfectionEngineV2;
        
        let lastInteractionTime = performance.now();
        let state = 'idle'; // idle, active, burst

        const updateState = (t) => {
          const diff = t - lastInteractionTime;
          if (diff > 5000) state = 'idle';
          else if (diff < 100) state = 'burst';
          else state = 'active';
          lastInteractionTime = t;
        };

        const getLatency = (t) => {
          let base = profile.baseLatency;
          if (state === 'idle') base += 20; // Cold start delay
          if (state === 'burst') base = Math.max(1, base - 5); // Continuous interaction faster
          
          const noise = eng.irregularNoise(t, profile.behaviorSeed);
          const spike = eng.microSpike(t, profile.behaviorSeed);
          
          return Math.max(0, base + (noise * 10) + (spike * 30));
        };

        const originalAEL = EventTarget.prototype.addEventListener;
        
        const newAEL = function addEventListener(type, listener, options) {
          if (['click', 'mousemove', 'keypress', 'keydown', 'pointerdown'].includes(type)) {
            const wrapped = function(e) {
              const t = performance.now();
              updateState(t);
              const latency = getLatency(t);
              
              if (latency > 0) {
                // Simulate processing latency synchronously
                const end = performance.now() + latency;
                while(performance.now() < end) { /* CPU load simulation */ }
              }
              return listener.apply(this, arguments);
            };
            return originalAEL.call(this, type, wrapped, options);
          }
          return originalAEL.call(this, type, listener, options);
        };
        
        EventTarget.prototype.addEventListener = newAEL;
        
        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newAEL, originalAEL);
        }
      })();
    ''';
  }
}
