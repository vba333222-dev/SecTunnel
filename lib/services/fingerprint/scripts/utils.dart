/// JavaScript utility functions for native function cloaking
/// This prevents detection via toString() and other introspection methods
class NativeUtils {
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
  
  const proxy = new Proxy(function() {}, handler);
  
  // Override toString to return native code signature
  Object.defineProperty(proxy, 'toString', {
    value: function() {
      return 'function $functionName() { [native code] }';
    },
    writable: false,
    configurable: false
  });
  
  // Override name property
  Object.defineProperty(proxy, 'name', {
    value: '$functionName',
    writable: false,
    configurable: false
  });
  
  return proxy;
})()
''';
  }
  
  /// Creates a native-looking getter function
  static String createNativeGetter(String propertyName, String returnValue) {
    return '''
Object.defineProperty(Object.getPrototypeOf(navigator), '$propertyName', {
  get: new Proxy(
    function get $propertyName() { return $returnValue; },
    {
      apply(target, thisArg, args) {
        return $returnValue;
      }
    }
  ),
  set: undefined,
  enumerable: true,
  configurable: true
});

// Override toString for the getter
Object.defineProperty(
  Object.getOwnPropertyDescriptor(Object.getPrototypeOf(navigator), '$propertyName').get,
  'toString',
  {
    value: function() {
      return 'function get $propertyName() { [native code] }';
    },
    writable: false,
    configurable: false
  }
);
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
  const protected = new Proxy(spoofed, {
    apply: function(target, thisArg, args) {
      return target.apply(thisArg, args);
    }
  });
  
  // Make toString return native code
  Object.defineProperty(protected, 'toString', {
    value: function() {
      return original.toString();
    },
    writable: false,
    configurable: false
  });
  
  // Make toSource return native code (Firefox)
  if (protected.toSource) {
    Object.defineProperty(protected, 'toSource', {
      value: function() {
        return original.toSource();
      },
      writable: false,
      configurable: false
    });
  }
  
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
// Prevent navigator modification detection
(() => {
  const originalGetOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  
  Object.getOwnPropertyDescriptor = new Proxy(originalGetOwnPropertyDescriptor, {
    apply: function(target, thisArg, args) {
      const [obj, prop] = args;
      
      // If checking navigator properties, return as if unmodified
      if (obj === Navigator.prototype || obj === navigator) {
        const descriptor = target.apply(thisArg, args);
        if (descriptor && descriptor.get && descriptor.get.toString().includes('[native code]')) {
          return descriptor;
        }
      }
      
      return target.apply(thisArg, args);
    }
  });
  
  // Protect Object.getOwnPropertyDescriptor itself
  Object.defineProperty(Object.getOwnPropertyDescriptor, 'toString', {
    value: function() {
      return 'function getOwnPropertyDescriptor() { [native code] }';
    }
  });
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
