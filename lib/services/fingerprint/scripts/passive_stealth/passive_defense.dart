class PassiveDefense {
  static String getJS() {
    return '''
      window.PassiveDefense = (function() {
        if (!window.EventLoopEngine || !window.SystemRhythm || !window.BackgroundActivity) return null;
        
        const loop = window.EventLoopEngine;
        const rhythm = window.SystemRhythm;
        const bg = window.BackgroundActivity;
        
        let isHidden = document.visibilityState === 'hidden';
        document.addEventListener('visibilitychange', () => {
          isHidden = document.visibilityState === 'hidden';
        });

        // Apply environmental context and mix noise
        return {
          applyTimingDefense: function(t, baseDelay = 0) {
            let delay = baseDelay;
            
            // 1. Rhythm factor
            delay *= rhythm.getRhythmFactor(t);
            
            // 2. Background activity jitter
            delay += bg.getIdleJitter(t);
            
            // 3. Event loop delay
            delay += loop.getTaskDelay(t);
            
            // 4. Runtime adaptation (visibility)
            if (isHidden) {
               delay *= 1.2; // Slower processing in background
            }
            
            return delay;
          },
          
          applyPromiseDefense: function(t) {
            return loop.getPromiseDelay(t);
          },
          
          applyFrameDefense: function(t) {
            return loop.getFrameDrop(t);
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[ENV] Runtime adaptation active");
      }
    ''';
  }
}
