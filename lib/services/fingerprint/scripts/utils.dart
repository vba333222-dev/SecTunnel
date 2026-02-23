/// JavaScript utility functions for native function cloaking
/// This prevents detection via toString() and other introspection methods
class NativeUtils {
  /// Global initialization for the cloaking mechanism.
  /// This must be injected before any other spoofing scripts.
  static String initCloaking() {
    return '''
// Initialize global cloaking mechanism
(() => {
  if (window.__pbrowser_cloak) return;
  
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
  
  // Expose cloak helper internally
  window.__pbrowser_cloak = function(fn, nativeStr) {
    let fnName = '';
    if (fn && typeof fn.name === 'string') {
        fnName = fn.name;
    }
    const str = nativeStr || `function ${fnName}() { [native code] }`;
    fns.set(fn, str);
    return fn;
  };
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
  window.__pbrowser_cloak(proxy, 'function $functionName() { [native code] }');
  
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
  
  window.__pbrowser_cloak(getterFn, 'function get $propertyName() { [native code] }');
  
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
  const protected = new Proxy(original || function() {}, {
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
  
  window.__pbrowser_cloak(protected, nativeStr);
  
  // Replace the method
  $objectPath.$methodName = protected;
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
  
  /// Prevents detection of modified navigator properties
  static String preventNavigatorDetection() {
    return '''
// Prevent navigator modification detection via getOwnPropertyDescriptor
(() => {
  const originalGetOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  
  const protected = new Proxy(originalGetOwnPropertyDescriptor, {
    apply: function(target, thisArg, args) {
      const [obj, prop] = args;
      
      // If checking navigator properties, return as if unmodified
      if (obj === Navigator.prototype || obj === (window.navigator || navigator)) {
        const descriptor = Reflect.apply(target, thisArg, args);
        if (descriptor && descriptor.get && window.__pbrowser_cloak) {
            // Mask that it's configurable or custom if needed
            return descriptor; 
        }
      }
      
      return Reflect.apply(target, thisArg, args);
    }
  });
  
  window.__pbrowser_cloak(protected, Function.prototype.toString.call(originalGetOwnPropertyDescriptor));
  Object.getOwnPropertyDescriptor = protected;
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

