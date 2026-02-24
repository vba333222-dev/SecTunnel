import 'package:pbrowser/models/fingerprint_config.dart';

class ScrollbarSpoof {
  static String generate(FingerprintConfig config) {
    return '''
  // --- SCROLLBAR WIDTH SPOOF (DOM Fingerprinting Evasion) ---
  (() => {
    try {
      const SCROLLBAR_WIDTH = 17;

      const nativeClientWidth = Object.getOwnPropertyDescriptor(Element.prototype, 'clientWidth').get;
      const nativeClientHeight = Object.getOwnPropertyDescriptor(Element.prototype, 'clientHeight').get;
      const nativeScrollHeight = Object.getOwnPropertyDescriptor(Element.prototype, 'scrollHeight').get;
      const nativeScrollWidth = Object.getOwnPropertyDescriptor(Element.prototype, 'scrollWidth').get;

      function hasVerticalScrollbar(element) {
          const cHeight = nativeClientHeight.call(element);
          const sHeight = nativeScrollHeight.call(element);
          
          if (element === document.documentElement || element === document.body) {
              return sHeight > window.innerHeight;
          }

          if (sHeight > cHeight) {
              const overflowY = window.getComputedStyle(element).overflowY;
              return overflowY === 'auto' || overflowY === 'scroll';
          } else {
              return window.getComputedStyle(element).overflowY === 'scroll';
          }
      }

      function hasHorizontalScrollbar(element) {
          const cWidth = nativeClientWidth.call(element);
          const sWidth = nativeScrollWidth.call(element);
          
          if (element === document.documentElement || element === document.body) {
              return sWidth > window.innerWidth;
          }

          if (sWidth > cWidth) {
              const overflowX = window.getComputedStyle(element).overflowX;
              return overflowX === 'auto' || overflowX === 'scroll';
          } else {
              return window.getComputedStyle(element).overflowX === 'scroll';
          }
      }

      function spoofedClientWidth() {
          let width = nativeClientWidth.call(this);
          if (width > 0 && hasVerticalScrollbar(this)) {
              width -= SCROLLBAR_WIDTH;
          }
          return width;
      }

      function spoofedClientHeight() {
          let height = nativeClientHeight.call(this);
          if (height > 0 && hasHorizontalScrollbar(this)) {
              height -= SCROLLBAR_WIDTH;
          }
          return height;
      }

      // Gunakan NativeUtils.cloak jika tersedia, jika tidak gunakan fallback
      if (typeof window.__pbrowser_cloak === 'function') {
          window.__pbrowser_cloak(spoofedClientWidth, 'get clientWidth', nativeClientWidth);
          window.__pbrowser_cloak(spoofedClientHeight, 'get clientHeight', nativeClientHeight);
      } else {
          const spoofToString = (func, name) => {
              const nativeString = `function get \${name}() { [native code] }`;
              Object.defineProperty(func, 'toString', {
                  value: () => nativeString, configurable: true, enumerable: false, writable: true
              });
          };
          spoofToString(spoofedClientWidth, 'clientWidth');
          spoofToString(spoofedClientHeight, 'clientHeight');
      }

      Object.defineProperty(Element.prototype, 'clientWidth', {
          get: spoofedClientWidth,
          configurable: true,
          enumerable: true
      });

      Object.defineProperty(Element.prototype, 'clientHeight', {
          get: spoofedClientHeight,
          configurable: true,
          enumerable: true
      });
    } catch (e) {
      // Ignored
    }
  })();
    ''';
  }
}
