class EventLatencyPatch {
  static String get jsCode => r'''
      // 3. INPUT LATENCY MODEL & 9. NETWORK LATENCY
      (function() {
        const originalAddEventListener = EventTarget.prototype.addEventListener;
        const originalFetch = window.fetch;
        const originalXhrOpen = XMLHttpRequest.prototype.open;

        // 5. IDLE STATE MODEL
        let _lastInteractionTime = performance.now();
        let _isIdle = false;

        function updateIdleState(time) {
          if (time - _lastInteractionTime > 5000) {
            _isIdle = true;
          } else {
            _isIdle = false;
          }
          _lastInteractionTime = time;
        }

        // 6. FOCUS / VISIBILITY
        let _isFocused = true;
        window.addEventListener('blur', () => _isFocused = false);
        window.addEventListener('focus', () => _isFocused = true);

        EmulationEngine.patchMethod(EventTarget.prototype, 'addEventListener', function(type, listener, options) {
          const inputTypes = ['click', 'mousedown', 'mouseup', 'mousemove', 'keydown', 'keyup', 'keypress'];
          
          if (inputTypes.includes(type) && typeof listener === 'function') {
            const wrappedListener = function(event) {
              const time = performance.now();
              updateIdleState(time);
              
              let delay = _BehaviorModel.getInteractionDelay(type, Math.round(time));
              if (_isIdle) delay += 2; // First interaction slower
              if (!_isFocused) delay += 3; // Occasional background state affects priority
              
              if (delay > 0 && delay < 20) {
                const start = performance.now();
                while (performance.now() - start < delay) {} // Micro pause
              }
              
              return listener.apply(this, arguments);
            };
            return originalAddEventListener.call(this, type, wrappedListener, options);
          }
          
          return originalAddEventListener.call(this, type, listener, options);
        });

        // 9. NETWORK LATENCY (LIGHT)
        if (originalFetch) {
          EmulationEngine.patchMethod(window, 'fetch', function(...args) {
            const latency = _BehaviorModel.getNetworkLatency();
            return new Promise((resolve) => {
              window.setTimeout(() => {
                resolve(originalFetch.apply(this, args));
              }, latency);
            });
          });
        }
        
        if (originalXhrOpen) {
          EmulationEngine.patchMethod(XMLHttpRequest.prototype, 'open', function(...args) {
            const latency = _BehaviorModel.getNetworkLatency();
            const start = performance.now();
            while (performance.now() - start < latency) {} 
            return originalXhrOpen.apply(this, args);
          });
        }

        console.debug("[BEHAVIOR] Input latency applied");
      })();
''';
}
