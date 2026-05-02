import 'package:SecTunnel/models/fingerprint_config.dart';

class BehaviorEngine {
  static String generate(FingerprintConfig config) {
    final seed = config.sessionBoundSeed.abs();

    return '''
// ===== BEHAVIORAL REALISM ENGINE =====
(() => {
  try {
    const seed = $seed;
    
    console.debug('[BEHAVIOR] Engine initialized');
    
    // Deterministic PRNG based on session seed
    let _behaviorSeed = seed;
    function getNext() {
      _behaviorSeed = (_behaviorSeed * 9301 + 49297) % 233280;
      return _behaviorSeed / 233280;
    }
    
    // --- 8. IDLE PATTERN ---
    let isIdle = false;
    let lastActive = performance.now();
    function checkIdle() {
      if (performance.now() - lastActive > 2000 + (getNext() * 3000)) {
        isIdle = true;
      }
    }
    setInterval(checkIdle, 1000);
    
    function markActive() {
      isIdle = false;
      lastActive = performance.now();
    }
    
    // --- 1. EVENT TIMING MODEL & 5. CPU LOAD SIMULATION ---
    console.debug('[BEHAVIOR] Event timing active');
    
    let cpuLoad = getNext() * 2; // 0 to 2ms base delay
    setInterval(() => {
      cpuLoad = getNext() * 3;
    }, 5000);
    
    const _origSetTimeout = window.setTimeout;
    self.__pbrowser_cloak(_origSetTimeout, window, 'setTimeout');
    window.setTimeout = function(handler, timeout, ...args) {
      markActive();
      const extraDelay = (getNext() * 4) + 1 + cpuLoad;
      const newTimeout = (timeout || 0) + extraDelay;
      return _origSetTimeout.call(this, handler, newTimeout, ...args);
    };
    self.__pbrowser_cloak(window.setTimeout, window, 'setTimeout');
    
    // --- 4. RENDER LOOP VARIATION ---
    const _origRequestAnimationFrame = window.requestAnimationFrame;
    self.__pbrowser_cloak(_origRequestAnimationFrame, window, 'requestAnimationFrame');
    window.requestAnimationFrame = function(callback) {
      markActive();
      const variance = getNext() * 2;
      const wrappedCallback = function(time) {
        const start = performance.now();
        while(performance.now() - start < cpuLoad) {} 
        return callback(time + variance);
      };
      return _origRequestAnimationFrame.call(this, wrappedCallback);
    };
    self.__pbrowser_cloak(window.requestAnimationFrame, window, 'requestAnimationFrame');
    
    // Promise.then delay (Micro-task scheduling variance)
    const _origPromiseThen = Promise.prototype.then;
    self.__pbrowser_cloak(_origPromiseThen, Promise.prototype, 'then');
    Promise.prototype.then = function(onFulfilled, onRejected) {
      const wrappedFulfilled = onFulfilled ? function(value) {
        if (getNext() > 0.8) {
          const start = performance.now();
          while(performance.now() - start < 1) {} // 1ms delay
        }
        return onFulfilled(value);
      } : undefined;
      return _origPromiseThen.call(this, wrappedFulfilled, onRejected);
    };
    self.__pbrowser_cloak(Promise.prototype.then, Promise.prototype, 'then');

    // --- 2. INPUT LATENCY SIMULATION ---
    const _origAddEventListener = EventTarget.prototype.addEventListener;
    self.__pbrowser_cloak(_origAddEventListener, EventTarget.prototype, 'addEventListener');
    EventTarget.prototype.addEventListener = function(type, listener, options) {
      if (['mousemove', 'click', 'keydown', 'pointerdown', 'touchstart'].includes(type) && typeof listener === 'function') {
        const wrappedListener = function(event) {
          markActive();
          const isFirst = (performance.now() - lastActive) > 1000;
          const delay = isFirst ? 2 + getNext() * 3 : getNext() * 1.5;
          
          if (delay > 0 && !event._isBehaviorWrapped) {
            event._isBehaviorWrapped = true;
            _origSetTimeout.call(window, () => listener.call(this, event), delay);
          } else {
            return listener.call(this, event);
          }
        };
        return _origAddEventListener.call(this, type, wrappedListener, options);
      }
      return _origAddEventListener.call(this, type, listener, options);
    };
    self.__pbrowser_cloak(EventTarget.prototype.addEventListener, EventTarget.prototype, 'addEventListener');

    // --- 3. SCROLL BEHAVIOR MODEL ---
    console.debug('[BEHAVIOR] Scroll model active');
    const _origScrollTo = window.scrollTo;
    if (_origScrollTo) {
      self.__pbrowser_cloak(_origScrollTo, window, 'scrollTo');
      window.scrollTo = function(...args) {
        markActive();
        if (args.length === 2 && typeof args[0] === 'number' && typeof args[1] === 'number') {
          args[0] += (getNext() > 0.8) ? (getNext() * 2) - 1 : 0;
          args[1] += (getNext() > 0.8) ? (getNext() * 2) - 1 : 0;
        } else if (args.length === 1 && typeof args[0] === 'object') {
          if (args[0].left !== undefined && getNext() > 0.8) args[0].left += (getNext() * 2) - 1;
          if (args[0].top !== undefined && getNext() > 0.8) args[0].top += (getNext() * 2) - 1;
        }
        return _origScrollTo.apply(this, args);
      };
      self.__pbrowser_cloak(window.scrollTo, window, 'scrollTo');
    }

    // --- 6. NETWORK BEHAVIOR (LIGHT) ---
    const _origFetch = window.fetch;
    self.__pbrowser_cloak(_origFetch, window, 'fetch');
    window.fetch = function(...args) {
      markActive();
      const delay = 1 + getNext() * 4;
      return new Promise((resolve, reject) => {
        _origSetTimeout.call(window, () => {
          _origFetch.apply(this, args).then(resolve).catch(reject);
        }, delay);
      });
    };
    self.__pbrowser_cloak(window.fetch, window, 'fetch');

    const _origSend = XMLHttpRequest.prototype.send;
    self.__pbrowser_cloak(_origSend, XMLHttpRequest.prototype, 'send');
    XMLHttpRequest.prototype.send = function(...args) {
      markActive();
      const delay = 1 + getNext() * 4;
      _origSetTimeout.call(window, () => {
        _origSend.apply(this, args);
      }, delay);
    };
    self.__pbrowser_cloak(XMLHttpRequest.prototype.send, XMLHttpRequest.prototype, 'send');

    // --- 7. FOCUS / VISIBILITY STATE ---
    const _origHasFocus = document.hasFocus;
    if (_origHasFocus) {
      self.__pbrowser_cloak(_origHasFocus, document, 'hasFocus');
      document.hasFocus = function() {
        if (isIdle && getNext() > 0.85) return false;
        return _origHasFocus.call(this);
      };
      self.__pbrowser_cloak(document.hasFocus, document, 'hasFocus');
    }

  } catch(e) {}
})();
''';
  }
}
