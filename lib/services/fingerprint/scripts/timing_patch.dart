class TimingPatch {
  static String get jsCode => r'''
      // 2. EVENT TIMING SIMULATION & 7. RENDER LOOP VARIATION
      (function() {
        const originalSetTimeout = window.setTimeout;
        const originalRequestAnimationFrame = window.requestAnimationFrame;
        const originalPromiseThen = Promise.prototype.then;
        
        // 8. CPU LOAD SIMULATION
        function simulateCpuLoadDelay() {
          const time = performance.now();
          const jitter = _BehaviorModel.getEventJitter(Math.round(time * 10));
          // Busy-wait to simulate real execution delay variation
          if (jitter > 1.5) {
             const start = performance.now();
             while (performance.now() - start < jitter) {}
          }
        }

        EmulationEngine.patchMethod(window, 'setTimeout', function(handler, timeout, ...args) {
          const time = performance.now();
          const jitter = _BehaviorModel.getEventJitter(Math.round(time));
          const adjustedTimeout = (timeout || 0) + jitter;
          
          const wrappedHandler = typeof handler === 'function' ? function(...cbArgs) {
            simulateCpuLoadDelay();
            return handler.apply(this, cbArgs);
          } : handler;
          
          return originalSetTimeout.call(this, wrappedHandler, adjustedTimeout, ...args);
        });

        EmulationEngine.patchMethod(window, 'requestAnimationFrame', function(callback) {
          const wrappedCallback = function(time) {
            const jitter = _BehaviorModel.getEventJitter(Math.round(time));
            simulateCpuLoadDelay();
            return callback(time + jitter);
          };
          return originalRequestAnimationFrame.call(this, wrappedCallback);
        });

        EmulationEngine.patchMethod(Promise.prototype, 'then', function(onFulfilled, onRejected) {
          const wrappedFulfilled = typeof onFulfilled === 'function' ? function(val) {
            simulateCpuLoadDelay();
            return onFulfilled(val);
          } : onFulfilled;
          
          const wrappedRejected = typeof onRejected === 'function' ? function(err) {
            simulateCpuLoadDelay();
            return onRejected(err);
          } : onRejected;
          
          return originalPromiseThen.call(this, wrappedFulfilled, wrappedRejected);
        });

        console.debug("[BEHAVIOR] Timing variation active");
      })();
''';
}
