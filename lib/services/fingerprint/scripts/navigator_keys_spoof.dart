import 'package:SecTunnel/models/fingerprint_config.dart';

/// Spoofs the iteration order of properties on Navigator.prototype to match
/// the standard V8 C++ binding order of a native Windows Chrome Desktop build.
/// This defeats advanced trackers that check if 'userAgent' or other properties
/// appear at the end of the Object.keys() array (a signature of JS mocking).
class NavigatorKeysSpoof {
  static String generate(FingerprintConfig config) {
    return '''
// === PROPERTY KEY ORDER EVASION ===
(() => {
  try {
    // Exact ownKeys length & order for Chrome 120+ Desktop (Windows)
    const desktopKeys = [
      'vendorSub', 'productSub', 'vendor', 'maxTouchPoints', 'scheduling', 
      'userActivation', 'doNotTrack', 'geolocation', 'connection', 'plugins', 
      'mimeTypes', 'pdfViewerEnabled', 'webkitTemporaryStorage', 
      'webkitPersistentStorage', 'windowControlsOverlay', 'hardwareConcurrency', 
      'cookieEnabled', 'appCodeName', 'appName', 'appVersion', 'platform', 
      'product', 'userAgent', 'language', 'languages', 'onLine', 'webdriver', 
      'getGamepads', 'javaEnabled', 'sendBeacon', 'vibrate', 'ink', 
      'mediaCapabilities', 'mediaSession', 'permissions', 'locks', 'credentials', 
      'storageBuckets', 'clipboard', 'managed', 'mediaDevices', 'storage', 
      'serviceWorker', 'virtualKeyboard', 'wakeLock', 'deviceMemory', 
      'userAgentData', 'login', 'keyboard', 'bluetooth', 'hid', 'serial', 
      'usb', 'xr', 'presentation', 'clearAppBadge', 'getBattery', 'getUserAgent', 
      'setAppBadge'
    ];

    // Global interception for Object.keys / getOwnPropertyNames
    const hookKeys = (obj, method, spoofedArray) => {
      const orig = obj[method];
      if (!orig) return;
      
      const hooked = new Proxy(orig, {
        apply(target, thisArg, args) {
          const argObj = args[0];
          // Target both the prototype and the instance to be completely safe
          if (argObj === Navigator.prototype || argObj === navigator) {
            return spoofedArray; 
          }
          return Reflect.apply(target, thisArg, args);
        }
      });
      self.__pbrowser_cloak(hooked, `function \${method}() { [native code] }`);
      obj[method] = hooked;
    };

    hookKeys(Object, 'keys', desktopKeys);
    hookKeys(Object, 'getOwnPropertyNames', desktopKeys);
    if (typeof Reflect !== 'undefined' && Reflect.ownKeys) {
      hookKeys(Reflect, 'ownKeys', desktopKeys);
    }
    
    // Also protect Object.entries and Object.values
    const origEntries = Object.entries;
    if (origEntries) {
      const spoofedEntries = new Proxy(origEntries, {
        apply(target, thisArg, args) {
          const argObj = args[0];
          if (argObj === Navigator.prototype || argObj === navigator) {
             return desktopKeys.map(k => [k, argObj[k]]);
          }
          return Reflect.apply(target, thisArg, args);
        }
      });
      self.__pbrowser_cloak(spoofedEntries, `function entries() { [native code] }`);
      Object.entries = spoofedEntries;
    }

    const origValues = Object.values;
    if (origValues) {
      const spoofedValues = new Proxy(origValues, {
        apply(target, thisArg, args) {
          const argObj = args[0];
          if (argObj === Navigator.prototype || argObj === navigator) {
             return desktopKeys.map(k => argObj[k]);
          }
          return Reflect.apply(target, thisArg, args);
        }
      });
      self.__pbrowser_cloak(spoofedValues, `function values() { [native code] }`);
      Object.values = spoofedValues;
    }

    // Wrap the window.navigator object completely in a Proxy 
    // to shield any direct instance inspection.
    const _origNavigator = navigator;
    const navigatorProxy = new Proxy(_origNavigator, {
      ownKeys(target) {
        // To natively emulate Chrome, navigator actually has NO own properties.
        // It inherits everything from Navigator.prototype.
        return [];
      },
      getOwnPropertyDescriptor(target, prop) {
        // Because ownKeys returns [], getOwnPropertyDescriptor must not expose
        // inserted own properties on the WebView's navigator instance.
        return undefined;
      },
      has(target, prop) {
        if (desktopKeys.includes(prop)) return true;
        return Reflect.has(target, prop);
      },
      get(target, prop, receiver) {
        if (prop === 'toString') return () => '[object Navigator]';
        
        // Return spoofed methods wrapped carefully to avoid illegal invocation errors
        const val = Reflect.get(target, prop, receiver);
        if (typeof val === 'function') {
           return val.bind(target);
        }
        return val;
      }
    });

    Object.defineProperty(window, 'navigator', {
      value: navigatorProxy,
      enumerable: true,
      configurable: false,
      writable: false
    });

  } catch(e) {}
})();
''';
  }
}
