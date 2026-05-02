class TimingPatchV2 {
  static String getJS() {
    return '''
      (function() {
        if (!window.BehaviorProfile || !window.ImperfectionEngineV2) return;
        
        const originalSetTimeout = window.setTimeout;
        const originalNow = performance.now;
        const originalRAF = window.requestAnimationFrame;
        
        const profile = window.BehaviorProfile;
        const eng = window.ImperfectionEngineV2;
        
        let sessionStart = originalNow.call(performance);
        
        // Visibility state tracking
        let isHidden = document.visibilityState === 'hidden';
        document.addEventListener('visibilitychange', () => {
          isHidden = document.visibilityState === 'hidden';
        });

        // performance.now patch
        const newNow = function now() {
          const t = originalNow.call(this);
          const elapsed = t - sessionStart;
          
          // Apply bounded drift + micro spike
          let noise = eng.drift(elapsed, profile.behaviorSeed) * profile.jitterIntensity;
          let spike = eng.microSpike(elapsed, profile.behaviorSeed) * profile.jitterIntensity;
          
          return t + noise + spike;
        };

        Object.defineProperty(Performance.prototype, 'now', {
          value: newNow,
          configurable: true,
          writable: true
        });

        // setTimeout patch
        const newSetTimeout = function setTimeout(handler, timeout, ...args) {
          let adjustedTimeout = timeout || 0;
          
          const t = originalNow.call(performance);
          let spike = eng.microSpike(t, profile.behaviorSeed);
          let noise = eng.irregularNoise(t, profile.behaviorSeed);
          
          let jitter = (profile.baseLatency + (noise * 5) + (spike * 20)) * profile.jitterIntensity;
          
          if (isHidden) {
            jitter *= 1.5; // slower when hidden
          }
          
          adjustedTimeout += Math.max(0, jitter);
          
          return originalSetTimeout.call(this, handler, adjustedTimeout, ...args);
        };
        
        window.setTimeout = newSetTimeout;
        
        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newNow, originalNow);
          window.FunctionCloaker.cloak(newSetTimeout, originalSetTimeout);
        }
      })();
    ''';
  }
}
