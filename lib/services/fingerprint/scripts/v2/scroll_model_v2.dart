class ScrollModelV2 {
  static String getJS() {
    return '''
      (function() {
        if (!window.BehaviorProfile || !window.ImperfectionEngineV2) return;
        
        const profile = window.BehaviorProfile;
        const eng = window.ImperfectionEngineV2;
        
        const originalScrollTo = window.scrollTo;
        const originalScrollBy = window.scrollBy;
        const originalScroll = window.scroll;
        
        const isMobile = window.DeviceContext && window.DeviceContext.deviceClass === 'mobile';
        
        function simulateInertia(targetX, targetY, currentX, currentY) {
          const distanceX = targetX - currentX;
          const distanceY = targetY - currentY;
          
          if (Math.abs(distanceX) < 1 && Math.abs(distanceY) < 1) {
            originalScrollTo.call(window, targetX, targetY);
            return;
          }
          
          const t = performance.now();
          const noise = eng.irregularNoise(t, profile.behaviorSeed);
          
          // Friction model: slower towards the end
          let inertia = profile.scrollInertia;
          if (isMobile) inertia += (noise * 0.05); // more erratic on touch
          
          const stepX = distanceX * (1 - inertia);
          const stepY = distanceY * (1 - inertia);
          
          originalScrollBy.call(window, stepX, stepY);
          
          window.requestAnimationFrame(() => {
            simulateInertia(targetX, targetY, currentX + stepX, currentY + stepY);
          });
        }
        
        const newScrollTo = function(x, y) {
          let targetX = typeof x === 'object' ? x.left : x;
          let targetY = typeof x === 'object' ? x.top : y;
          
          if (targetX === undefined) targetX = window.scrollX;
          if (targetY === undefined) targetY = window.scrollY;
          
          const t = performance.now();
          const spike = eng.microSpike(t, profile.behaviorSeed);
          
          // Micro anomaly: scroll slightly past and bounce back rarely
          if (spike > 0) {
            targetY += (spike * 50);
          }
          
          simulateInertia(targetX, targetY, window.scrollX, window.scrollY);
        };
        
        window.scrollTo = newScrollTo;
        window.scroll = newScrollTo;
        
        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newScrollTo, originalScrollTo);
          window.FunctionCloaker.cloak(newScrollTo, originalScroll);
        }
      })();
    ''';
  }
}
