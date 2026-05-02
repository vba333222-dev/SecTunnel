class BehaviorEngine {
  static String generate(int sessionSeed, int hardwareConcurrency, bool isMobile) {
    return '''
      // 1. BEHAVIOR ENGINE CORE
      const _behaviorSeed = $sessionSeed;
      const _hwConcurrency = $hardwareConcurrency;
      const _isMobile = $isMobile;
      
      const _BehaviorModel = {
        _xorshift(state) {
          state ^= state << 13;
          state ^= state >> 17;
          state ^= state << 5;
          return state >>> 0;
        },
        
        getDeviceMultiplier() {
          let mult = 1.0;
          if (_hwConcurrency >= 8) mult *= 0.5; // Fast CPU -> lower delay
          else if (_hwConcurrency <= 4) mult *= 1.5; // Slow CPU -> higher delay
          
          if (_isMobile) mult *= 1.3; // Mobile -> higher latency
          return mult;
        },
        
        getInteractionDelay(type, time) {
          let s = this._xorshift(_behaviorSeed ^ time ^ type.charCodeAt(0));
          let norm = s / 4294967296;
          
          let baseDelay = 1;
          let variance = 4;
          
          if (type === 'mousemove') {
            baseDelay = 0.5; variance = 1.5;
          } else if (type === 'keydown' || type === 'keyup') {
            baseDelay = 2; variance = 5;
          }
          
          return (baseDelay + (norm * variance)) * this.getDeviceMultiplier();
        },
        
        getScrollVelocity(time, position) {
          let s = this._xorshift(_behaviorSeed ^ Math.round(position));
          let norm = s / 4294967296;
          return 0.8 + (norm * 0.4); 
        },
        
        getEventJitter(time) {
          let s = this._xorshift(_behaviorSeed ^ time);
          let norm = s / 4294967296;
          return (norm * 2.0) * this.getDeviceMultiplier(); 
        },

        getNetworkLatency() {
          let time = Date.now();
          let s = this._xorshift(_behaviorSeed ^ Math.round(time / 1000));
          let norm = s / 4294967296;
          let latency = 5 + (norm * 15);
          return _isMobile ? latency * 1.5 : latency;
        }
      };

      console.debug("[BEHAVIOR] Engine initialized");
''';
  }
}
