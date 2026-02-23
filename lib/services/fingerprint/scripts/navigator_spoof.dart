import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// JavaScript code generator for navigator spoofing
class NavigatorSpoof {
  static String generate(FingerprintConfig config) {
    final userAgent = _escapeJs(config.userAgent);
    final platform = _escapeJs(config.platform);
    final language = _escapeJs(config.language);
    
    return '''
// ===== NAVIGATOR SPOOFING =====
(() => {
  // Advanced Property Descriptor masking to defeat checking mechanisms
  const modifyNavigatorProp = (propName, value) => {
    try {
      if (typeof value === 'function' || typeof value === 'object') {
        Object.defineProperty(Navigator.prototype, propName, {
          get: new Proxy(
            Object.getOwnPropertyDescriptor(Navigator.prototype, propName)?.get || function() { return value; },
            {
              apply(target, thisArg, args) {
                return value;
              }
            }
          ),
          enumerable: true,
          configurable: true
        });
      } else {
        Object.defineProperty(Navigator.prototype, propName, {
          get: function() { return value; },
          set: undefined,
          enumerable: true,
          configurable: true
        });
      }
    } catch(e){}
  };

  // Mock primary ident properties
  modifyNavigatorProp('userAgent', '\$userAgent');
  modifyNavigatorProp('appVersion', '\$userAgent'.replace('Mozilla/', ''));
  modifyNavigatorProp('platform', '\$platform');
  modifyNavigatorProp('language', '\$language');
  modifyNavigatorProp('languages', ['\$language']);
  modifyNavigatorProp('hardwareConcurrency', \${config.hardwareConcurrency});
  
  if ('deviceMemory' in navigator) {
    modifyNavigatorProp('deviceMemory', \${config.deviceMemory});
  }

  // ===== WebDriver Hardening =====
  // Bots actively attempt to delete navigator.webdriver or check its descriptors.
  try {
    Object.defineProperty(Navigator.prototype, 'webdriver', {
      get: new Proxy(
        Object.getOwnPropertyDescriptor(Navigator.prototype, 'webdriver')?.get || function() { return false; },
        {
          apply(target, thisArg, args) {
            return false;
          }
        }
      ),
      set: undefined,
      enumerable: true,
      configurable: true // Must be configurable so scripts testing deletion don't fail, but they just redefine our proxy.
    });
  } catch(e) {}

  // Basic Plugin Mocking with Prototype masking
  (() => {
    const mockPlugins = {
      length: 0,
      item: function(i) { return null; },
      namedItem: function(name) { return null; },
      refresh: function() {}
    };
    Object.setPrototypeOf(mockPlugins, PluginArray.prototype);
    modifyNavigatorProp('plugins', mockPlugins);
    
    const mockMimeTypes = {
      length: 0,
      item: function(i) { return null; },
      namedItem: function(name) { return null; }
    };
    Object.setPrototypeOf(mockMimeTypes, MimeTypeArray.prototype);
    modifyNavigatorProp('mimeTypes', mockMimeTypes);
  })();

  // ===== SCREEN SPOOFING =====
  // Override screen properties precisely on prototype to survive deep introspection
  const modifyScreenProp = (propName, value) => {
    try {
       const getterFn = new Proxy(
         Object.getOwnPropertyDescriptor(Screen.prototype, propName)?.get || function() { return value; },
         { apply() { return value; } }
       );
       
       Object.defineProperty(getterFn, 'name', { value: `get \${propName}`, configurable: true });
       window.__pbrowser_cloak(getterFn, `function get \${propName}() { [native code] }`);
       
       Object.defineProperty(Screen.prototype, propName, {
         get: getterFn,
         set: undefined,
         enumerable: true,
         configurable: true
       });
    } catch(e) {}
  };

  modifyScreenProp('width', \${config.screenResolution.width});
  modifyScreenProp('height', \${config.screenResolution.height});
  modifyScreenProp('availWidth', \${config.screenResolution.width});
  modifyScreenProp('availHeight', \${config.screenResolution.height - 40});
  modifyScreenProp('colorDepth', \${config.screenResolution.colorDepth});
  modifyScreenProp('pixelDepth', \${config.screenResolution.colorDepth});

})();
''';
  }
  
  static String _escapeJs(String str) {
    return str
        .replaceAll('\\\\', '\\\\\\\\')
        .replaceAll("'", "\\\\'")
        .replaceAll('"', '\\\\"')
        .replaceAll('\\n', '\\\\n')
        .replaceAll('\\r', '\\\\r');
  }
}
