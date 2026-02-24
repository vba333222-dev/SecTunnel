import 'package:pbrowser/models/fingerprint_config.dart';

/// Spoofs CSS Object Model capabilities to hide Android-specific CSS properties.
/// E.g. -webkit-tap-highlight-color is a dead giveaway for mobile WebViews.
class CSSMetricsSpoof {
  static String generate(FingerprintConfig config) {
    return '''
// === CSS CAPABILITY & COMPUTED STYLE SPOOFING ===
(() => {
  try {
    const _mobileCssProps = [
      '-webkit-tap-highlight-color',
      'webkitTapHighlightColor',
      '-webkit-touch-callout',
      'webkitTouchCallout',
      'text-size-adjust',
      'textSizeAdjust',
      '-webkit-text-size-adjust',
      'webkitTextSizeAdjust'
    ];

    const _isMobileProp = (prop) => {
      if (!prop) return false;
      const str = String(prop).toLowerCase();
      return _mobileCssProps.some(m => str === m.toLowerCase() || str.includes(m.toLowerCase()));
    };

    // 1. Hook CSS.supports
    if (typeof CSS !== 'undefined' && CSS.supports) {
      const origSupports = CSS.supports;
      const spoofedSupports = function(...args) {
        if (args.length > 0 && _isMobileProp(args[0])) {
          return false; // Force it to pretend Desktop Chrome doesn't support tap-highlight
        }
        return origSupports.apply(this, args);
      };
      self.__pbrowser_cloak(spoofedSupports, 'function supports() { [native code] }');
      CSS.supports = spoofedSupports;
    }

    // 2. Hook window.getComputedStyle
    if (typeof window !== 'undefined' && window.getComputedStyle) {
      const origGetComputedStyle = window.getComputedStyle;
      const spoofedGetComputedStyle = function(elt, pseudoElt) {
        const origStyle = origGetComputedStyle.call(this, elt, pseudoElt);
        
        // We wrap the returned CSSStyleDeclaration in a Proxy to hide mobile props
        if (origStyle) {
           return new Proxy(origStyle, {
              get(target, prop, receiver) {
                 if (_isMobileProp(prop)) {
                    return ''; // Return empty string for unsupported properties
                 }
                 // If they try to read getPropertyValue
                 if (prop === 'getPropertyValue') {
                    return function(property) {
                       if (_isMobileProp(property)) return '';
                       const val = target.getPropertyValue(property);
                       return val;
                    };
                 }
                 const value = Reflect.get(target, prop, receiver);
                 if (typeof value === 'function') {
                    return value.bind(target);
                 }
                 return value;
              },
              has(target, prop) {
                 if (_isMobileProp(prop)) return false;
                 return Reflect.has(target, prop);
              },
              ownKeys(target) {
                 // Filter out mobile properties from Object.keys() / iteration
                 const keys = Reflect.ownKeys(target);
                 return keys.filter(k => !_isMobileProp(k));
              },
              getOwnPropertyDescriptor(target, prop) {
                 if (_isMobileProp(prop)) return undefined;
                 return Reflect.getOwnPropertyDescriptor(target, prop);
              }
           });
        }
        return origStyle;
      };
      self.__pbrowser_cloak(spoofedGetComputedStyle, 'function getComputedStyle() { [native code] }');
      window.getComputedStyle = spoofedGetComputedStyle;
    }

    // 3. Prevent detection via CSSStyleDeclaration.prototype directly
    if (typeof CSSStyleDeclaration !== 'undefined' && CSSStyleDeclaration.prototype) {
      const origGetPropertyValue = CSSStyleDeclaration.prototype.getPropertyValue;
      if (origGetPropertyValue) {
         const spoofedGetPropertyValue = function(property) {
            if (_isMobileProp(property)) return '';
            return origGetPropertyValue.apply(this, arguments);
         };
         self.__pbrowser_cloak(spoofedGetPropertyValue, 'function getPropertyValue() { [native code] }');
         CSSStyleDeclaration.prototype.getPropertyValue = spoofedGetPropertyValue;
      }
      
      const origSetProperty = CSSStyleDeclaration.prototype.setProperty;
      if (origSetProperty) {
         const spoofedSetProperty = function(property, value, priority) {
            if (_isMobileProp(property)) return; // Silently ignore setting mobile props
            return origSetProperty.apply(this, arguments);
         };
         self.__pbrowser_cloak(spoofedSetProperty, 'function setProperty() { [native code] }');
         CSSStyleDeclaration.prototype.setProperty = spoofedSetProperty;
      }
    }

  } catch (e) {}
})();
''';
  }
}
