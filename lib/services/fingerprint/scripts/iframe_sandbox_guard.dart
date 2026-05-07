import 'package:sec_tunnel/models/fingerprint_config.dart';

/// Prevents sandbox evasion by eagerly injecting the main anti-detect payload
/// into dynamically created `about:blank` iframes before trackers can read them.
class IframeSandboxGuard {
  static String generate(FingerprintConfig config) {
    return '''
// === IFRAME SANDBOX EVASION GUARD ===
(() => {
  try {
    const globalScope = (typeof window !== 'undefined' ? window : self);
    const _masterScript = globalScope.__pbrowser_master_script;

    if (!_masterScript) return; 

    // Secure propagation via Blob to bypass CSP eval restrictions
    let _blobUrl = null;
    try {
      const blob = new Blob([_masterScript], { type: 'text/javascript' });
      _blobUrl = URL.createObjectURL(blob);
    } catch (e) {}

    const _injectIntoWindow = (childWin) => {
      if (!childWin || childWin.__pbrowser_injected_secure) return;
      try {
        if (_blobUrl) {
          const script = childWin.document.createElement('script');
          script.src = _blobUrl;
          childWin.document.head.appendChild(script);
        } else {
          // Fallback to srcdoc for extremely restrictive environments
          // or direct execution if Blob failed
          childWin.eval(`(\${_masterScript})(window);`);
        }
      } catch (e) {}
    };

    const _hookInsertMethod = (NodeProto, methodName) => {
      const orig = NodeProto[methodName];
      if (!orig) return;

      const hooked = function(node, ...args) {
        const res = orig.apply(this, [node, ...args]);
        try {
          if (node && node.tagName && node.tagName.toLowerCase() === 'iframe') {
            _injectIntoWindow(node.contentWindow);
          }
        } catch (e) {}
        return res;
      };

      self.__pbrowser_cloak(hooked, `function \${methodName}() { [native code] }`);
      NodeProto[methodName] = hooked;
    };

    _hookInsertMethod(Node.prototype, 'appendChild');
    _hookInsertMethod(Node.prototype, 'insertBefore');
    _hookInsertMethod(Node.prototype, 'replaceChild');

    const _origCreateElement = Document.prototype.createElement;
    if (_origCreateElement) {
      const hookedCreate = function(tagName, options) {
        const el = _origCreateElement.call(this, tagName, options);
        if (tagName && String(tagName).toLowerCase() === 'iframe') {
           try {
              el.addEventListener('load', () => _injectIntoWindow(el.contentWindow), { once: true });
           } catch(e) {}
        }
        return el;
      };
      self.__pbrowser_cloak(hookedCreate, 'function createElement() { [native code] }');
      Document.prototype.createElement = hookedCreate;
    }

    // Fallback: MutationObserver
    try {
      const _mutObserver = new MutationObserver((mutations) => {
        for (const mut of mutations) {
          if (mut.addedNodes) {
            for (const node of mut.addedNodes) {
              if (node.tagName && node.tagName.toLowerCase() === 'iframe') {
                _injectIntoWindow(node.contentWindow);
              } else if (node.querySelectorAll) {
                try {
                  node.querySelectorAll('iframe').forEach(f => _injectIntoWindow(f.contentWindow));
                } catch(e){}
              }
            }
          }
        }
      });
      _mutObserver.observe(document.documentElement, { childList: true, subtree: true });
    } catch(e) {}

    // Property descriptor proxies
    const _proxyDesc = (proto, prop, originalDesc) => {
      if (!originalDesc || !originalDesc.get) return;
      const hooked = function() {
        const win = originalDesc.get.call(this);
        if (win && !win.__pbrowser_injected_secure) {
           _injectIntoWindow(win);
        }
        return win;
      };
      self.__pbrowser_cloak(hooked, `function get \${prop}() { [native code] }`);
      Object.defineProperty(proto, prop, {
          get: hooked, enumerable: true, configurable: true
      });
    };

    const iframeProto = HTMLIFrameElement.prototype;
    _proxyDesc(iframeProto, 'contentWindow', Object.getOwnPropertyDescriptor(iframeProto, 'contentWindow'));
    _proxyDesc(iframeProto, 'contentDocument', Object.getOwnPropertyDescriptor(iframeProto, 'contentDocument'));

    const objProto = HTMLObjectElement.prototype;
    _proxyDesc(objProto, 'contentDocument', Object.getOwnPropertyDescriptor(objProto, 'contentDocument'));

  } catch(e) {}
})();
''';
  }
}
