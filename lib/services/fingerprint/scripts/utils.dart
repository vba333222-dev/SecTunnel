/// JavaScript utility functions for native function cloaking
/// This prevents detection via toString() and other introspection methods
class NativeUtils {
  /// Global initialization for the cloaking mechanism.
  /// This must be injected before any other spoofing scripts.
  static String initCloaking() {
    return '''
// Initialize internal cloaking mechanism inside closure
(() => {
  if (typeof __pbrowser_cloak !== 'undefined') return; // Already initialized in this scope
  
  const fns = new WeakMap();
  const originalToString = Function.prototype.toString;
  
  const spoofToString = new Proxy(originalToString, {
    apply(target, thisArg, args) {
      if (fns.has(thisArg)) {
        return fns.get(thisArg);
      }
      return Reflect.apply(target, thisArg, args);
    }
  });
  
  // Cloak the toString itself
  fns.set(spoofToString, originalToString.call(originalToString));
  
  // Replace the global toString
  Function.prototype.toString = spoofToString;
  
  // Define cloak helper as a local constant in the parent closure
  // We will wrap ALL scripts in one giant IIFE later, so this behaves globally within our scope
  const __pbrowser_cloak = function(fn, nativeStr) {
    let fnName = '';
    if (fn && typeof fn.name === 'string') {
        fnName = fn.name;
    }
    const str = nativeStr || `function \${fnName}() { [native code] }`;
    fns.set(fn, str);
    return fn;
  };

  // Expose it to the IIFE scope
  self.__pbrowser_cloak = __pbrowser_cloak;
})();
''';
  }

  /// L-1 Session Entropy: mixes a per-session random salt so the same profile
  /// produces subtly different canvas/DOMRect/timing fingerprints across visits.
  /// The session salt is stored in sessionStorage — consistent within a tab session,
  /// but regenerated on each new tab / app restart.
  static String initSessionEntropy(int profileSeed) {
    return '''
// Session-level entropy mix
(() => {
  try {
    const _STORAGE_KEY = '__pbr_ss_' + $profileSeed;
    let sessionSalt = parseInt(sessionStorage.getItem(_STORAGE_KEY) || '0', 10);
    if (!sessionSalt || isNaN(sessionSalt)) {
      const _arr = new Uint32Array(1);
      crypto.getRandomValues(_arr);
      sessionSalt = _arr[0] & 0x0000FFFF;
      try { sessionStorage.setItem(_STORAGE_KEY, String(sessionSalt)); } catch(e) {}
    }
    // Instead of window., we expose it to the local IIFE scope
    self.__pbr_session_salt = sessionSalt;
  } catch(e) {
    self.__pbr_session_salt = 0;
  }
})();
''';
  }

  /// Wraps a function to make it appear as native code
  /// Usage: wrapNative(myFunction, 'functionName')
  static String wrapAsNative(String functionBody, String functionName) {
    return '''
// Native function wrapper for: $functionName
(() => {
  const handler = {
    apply: function(target, thisArg, argumentsList) {
      $functionBody
    }
  };
  
  const proxy = new Proxy(function $functionName() {}, handler);
  __pbrowser_cloak(proxy, 'function $functionName() { [native code] }');
  
  return proxy;
})()
''';
  }
  
  /// Creates a native-looking getter function
  static String createNativeGetter(String propertyName, String returnValue) {
    return '''
(() => {
  const getterFn = new Proxy(function get $propertyName() { return $returnValue; }, {
    apply(target, thisArg, args) {
      return $returnValue;
    }
  });
  
  __pbrowser_cloak(getterFn, 'function get $propertyName() { [native code] }');
  
  Object.defineProperty(Object.getPrototypeOf(navigator), '$propertyName', {
    get: getterFn,
    set: undefined,
    enumerable: true,
    configurable: true
  });
})();
''';
  }
  
  /// Protects a spoofed function from toString detection
  static String protectFunction(String objectPath, String methodName, String implementation) {
    return '''
// Protect $objectPath.$methodName from toString detection
(() => {
  const original = $objectPath.$methodName;
  const spoofed = $implementation;
  
  // Create proxy that behaves like spoofed but looks like original
  const _spoofProxy = new Proxy(original || function() {}, {
    apply: function(target, thisArg, args) {
      return Reflect.apply(spoofed, thisArg, args);
    },
    construct: function(target, args, newTarget) {
      return Reflect.construct(spoofed, args, newTarget);
    }
  });
  
  // Try to get original native string, fallback to standard template
  let nativeStr;
  try {
    nativeStr = Function.prototype.toString.call(original);
  } catch(e) {
    nativeStr = `function $methodName() { [native code] }`;
  }
  
  __pbrowser_cloak(_spoofProxy, nativeStr);
  
  // Replace the method
  $objectPath.$methodName = _spoofProxy;
})();
''';
  }
  
  /// Advanced seeded random number generator (Mulberry32)
  /// Returns consistent random values based on seed
  static String seededRandomFunction() {
    return '''
// Seeded random generator (Mulberry32 algorithm)
function seededRandom(seed) {
  return function() {
    seed = seed + 0x6D2B79F5 | 0;
    var t = Math.imul(seed ^ seed >>> 15, 1 | seed);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
''';
  }
  
  /// Prevents detection of modified navigator properties by masking descriptors
  static String preventNavigatorDetection() {
    return '''
// Prevent navigator modification detection via getOwnPropertyDescriptor / getOwnPropertyDescriptors
(() => {
  const _origGOPD  = Object.getOwnPropertyDescriptor;
  const _origGOPDs = Object.getOwnPropertyDescriptors;

  // Targets whose descriptors should be hardened
  const _targets = () => [
    typeof Navigator !== 'undefined' ? Navigator.prototype : null,
    typeof window !== 'undefined' ? window : null,
    typeof navigator !== 'undefined' ? navigator : null,
  ].filter(Boolean);

  // Strip configurable/writable flags from spoofed getter descriptors
  // so callers cannot redefine them over our overrides
  const _hardenDescriptor = (desc) => {
    if (!desc) return desc;
    const copy = Object.assign({}, desc);
    // If it's a getter-based prop, mark it non-configurable so re-override fails
    if (copy.get) {
      copy.configurable = false;
    }
    return copy;
  };

  const _spoofProxy = new Proxy(_origGOPD, {
    apply: function(target, thisArg, args) {
      const [obj, prop] = args;
      const desc = Reflect.apply(target, thisArg, args);
      if (_targets().includes(obj)) {
        return _hardenDescriptor(desc);
      }
      return desc;
    }
  });

  const _spoofProxyPlural = new Proxy(_origGOPDs, {
    apply: function(target, thisArg, args) {
      const [obj] = args;
      const descs = Reflect.apply(target, thisArg, args);
      if (_targets().includes(obj)) {
        const hardened = {};
        for (const key of Object.keys(descs)) {
          hardened[key] = _hardenDescriptor(descs[key]);
        }
        return hardened;
      }
      return descs;
    }
  });

  __pbrowser_cloak(_spoofProxy, Function.prototype.toString.call(_origGOPD));
  __pbrowser_cloak(_spoofProxyPlural, Function.prototype.toString.call(_origGOPDs));
  Object.getOwnPropertyDescriptor  = _spoofProxy;
  Object.getOwnPropertyDescriptors = _spoofProxyPlural;
})();
''';
  }
  
  /// Escape JavaScript string safely
  static String escapeJs(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}

