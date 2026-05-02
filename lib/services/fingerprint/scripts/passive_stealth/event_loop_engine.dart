class EventLoopEngine {
  static String getJS() {
    return '''
      window.EventLoopEngine = (function() {
        if (!window.IdentityCore) return null;
        const baseSeed = window.IdentityCore.getSeed();
        
        const _hash = function(str) {
          let h = 0x811c9dc5;
          for (let i = 0; i < str.length; i++) h ^= str.charCodeAt(i);
          return (h * 0x01000193) >>> 0;
        };

        const _xorshift = function(state) {
          let x = state;
          x ^= x << 13; x ^= x >>> 17; x ^= x << 5;
          return x >>> 0;
        };

        return {
          getTaskDelay: function(t) {
            // Simulate task queue variation & micro delay
            const state = _hash(baseSeed.toString() + "eventloop" + Math.floor(t / 10).toString());
            const r = (_xorshift(state) % 100) / 100.0;
            
            // 90% chance of no delay, 10% chance of micro delay (0.1 - 0.5ms)
            if (r > 0.90) return (r - 0.90) * 5.0; 
            return 0;
          },

          getPromiseDelay: function(t) {
            // Microtask queue irregularity
            const state = _hash(baseSeed.toString() + "promise" + Math.floor(t / 5).toString());
            const r = (_xorshift(state) % 1000) / 1000.0;
            
            if (r > 0.98) return 0.2; // very rare micro-delay reordering
            return 0;
          },

          getFrameDrop: function(t) {
            // Simulate frame drop (rare) & FPS instability
            const state = _hash(baseSeed.toString() + "raf" + Math.floor(t / 1000).toString());
            const r = (_xorshift(state) % 1000) / 1000.0;
            
            if (r > 0.99) return 16.6; // Drop one 60Hz frame
            if (r > 0.95) return r * 2.0; // slight uneven frame interval
            return 0;
          }
        };
      })();

      if (window.console && window.console.debug) {
         // console.debug("[PASSIVE] Event loop model active");
      }
    ''';
  }
}
