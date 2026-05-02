class ScrollModel {
  static String get jsCode => r'''
      // 4. SCROLL BEHAVIOR
      (function() {
        const originalScrollTo = Element.prototype.scrollTo || window.scrollTo;

        function applyProgressiveScroll(target, optionsOrX, y, originalMethod) {
          let targetX = 0;
          let targetY = 0;
          let isSmooth = false;
          
          if (typeof optionsOrX === 'object' && optionsOrX !== null) {
            targetX = optionsOrX.left !== undefined ? optionsOrX.left : target.scrollLeft;
            targetY = optionsOrX.top !== undefined ? optionsOrX.top : target.scrollTop;
            isSmooth = optionsOrX.behavior === 'smooth';
          } else {
            targetX = optionsOrX !== undefined ? optionsOrX : target.scrollLeft;
            targetY = y !== undefined ? y : target.scrollTop;
          }

          if (isSmooth) {
             return originalMethod.call(target, optionsOrX, y);
          }

          // Progressive scroll mapping based on determinisic velocity
          const time = performance.now();
          const velocity = _BehaviorModel.getScrollVelocity(time, targetY);
          
          let currentY = target.scrollTop || window.scrollY || 0;
          let distance = Math.abs(targetY - currentY);
          
          if (distance > 0 && distance < 1000) {
            const jitter = _BehaviorModel.getEventJitter(time);
            const delay = jitter * velocity;
            if (delay > 0) {
              const start = performance.now();
              while (performance.now() - start < delay) {}
            }
          }
          
          return originalMethod.call(target, optionsOrX, y);
        }

        if (originalScrollTo) {
          EmulationEngine.patchMethod(window, 'scrollTo', function(...args) {
            return applyProgressiveScroll(this, args[0], args[1], originalScrollTo);
          });
          EmulationEngine.patchMethod(Element.prototype, 'scrollTo', function(...args) {
            return applyProgressiveScroll(this, args[0], args[1], originalScrollTo);
          });
        }
        
        console.debug("[BEHAVIOR] Scroll model active");
      })();
''';
}
