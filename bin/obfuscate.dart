// ignore_for_file: avoid_print
import 'package:pbrowser/utils/security_obfuscator.dart';

void main() async {
  final wrapAsNative = r'''
// Native function wrapper for: __FUNC_NAME__
(() => {
  const handler = {
    apply: function(target, thisArg, argumentsList) {
      __FUNC_BODY__
    }
  };
  
  const proxy = new Proxy(function() {}, handler);
  
  // Override toString to return native code signature
  Object.defineProperty(proxy, 'toString', {
    value: function() {
      return 'function __FUNC_NAME__() { [native code] }';
    },
    writable: false,
    configurable: false
  });
  
  // Override name property
  Object.defineProperty(proxy, 'name', {
    value: '__FUNC_NAME__',
    writable: false,
    configurable: false
  });
  
  return proxy;
})()
''';

  final createNativeGetter = r'''
Object.defineProperty(Object.getPrototypeOf(navigator), '__PROP_NAME__', {
  get: new Proxy(
    function get __PROP_NAME__() { return __RET_VAL__; },
    {
      apply(target, thisArg, args) {
        return __RET_VAL__;
      }
    }
  ),
  set: undefined,
  enumerable: true,
  configurable: true
});

// Override toString for the getter
Object.defineProperty(
  Object.getOwnPropertyDescriptor(Object.getPrototypeOf(navigator), '__PROP_NAME__').get,
  'toString',
  {
    value: function() {
      return 'function get __PROP_NAME__() { [native code] }';
    },
    writable: false,
    configurable: false
  }
);
''';

  final protectFunction = r'''
// Protect __OBJ_PATH__.__METHOD_NAME__ from toString detection
(() => {
  const original = __OBJ_PATH__.__METHOD_NAME__;
  const spoofed = __IMPLEMENTATION__;
  
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
  __OBJ_PATH__.__METHOD_NAME__ = protected;
})();
''';

  final seededRandom = r'''
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

  final preventDet = r'''
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

  print('wrapAsNative:');
  print(SecurityObfuscator.encrypt(wrapAsNative));
  print('---');
  print('createNativeGetter:');
  print(SecurityObfuscator.encrypt(createNativeGetter));
  print('---');
  print('protectFunction:');
  print(SecurityObfuscator.encrypt(protectFunction));
  print('---');
  print('seededRandom:');
  print(SecurityObfuscator.encrypt(seededRandom));
  print('---');
  print('preventDet:');
  print(SecurityObfuscator.encrypt(preventDet));
}
