import 'package:SecTunnel/models/fingerprint_config.dart';

/// Prevents sandbox evasion by eagerly injecting the main anti-detect payload
/// into dynamically created `about:blank` iframes before trackers can read them.
class IframeSandboxGuard {
  static String generate(FingerprintConfig config) {
    return '''
// === IFRAME SANDBOX EVASION GUARD ===
(() => {
  try {
    // 1. Identify the master injection script string representation
    // We expect this script to be running inside an IIFE `(function(window) { ... })(window);`
    // We capture its exact source code so we can inject it recursively into child frames.
    const _masterScript = arguments.callee.caller ? arguments.callee.caller.toString() : null;

    if (!_masterScript) {
      console.warn('[PBrowser] Iframe Guard: Failed to locate master script caller.');
      return; 
    }

    // Helper: Execute master script in a child window context immediately
    const _injectIntoWindow = (childWin) => {
      if (!childWin || childWin.__pbrowser_injected_secure) return;
      try {
        // Execute the IIFE string wrapped around the child window context
        childWin.eval(`(\${_masterScript})(window);`);
      } catch (e) {
        // Cross-origin or eval blocked
      }
    };

    // Helper: Intercept DOM methods that insert nodes
    const _hookInsertMethod = (NodeProto, methodName) => {
      const orig = NodeProto[methodName];
      if (!orig) return;

      const hooked = function(node, ...args) {
        // If appending an iframe, we want to inject IMMEDIATELY after original insert
        // but BEFORE the JS event loop continues to the next instruction of the tracker script.
        const res = orig.apply(this, [node, ...args]);
        
        try {
          if (node && node.tagName && Object.is(node.tagName.toLowerCase(), 'iframe')) {
            _injectIntoWindow(node.contentWindow);
          }
        } catch (e) {}

        return res;
      };

      self.__pbrowser_cloak(hooked, `function \${methodName}() { [native code] }`);
      NodeProto[methodName] = hooked;
    };

    // Hook appendChild, insertBefore, replaceChild
    _hookInsertMethod(Node.prototype, 'appendChild');
    _hookInsertMethod(Node.prototype, 'insertBefore');
    _hookInsertMethod(Node.prototype, 'replaceChild');

    // 2. Intercept document.createElement just in case it's appended differently (e.g. innerHTML parent)
    const _origCreateElement = Document.prototype.createElement;
    if (_origCreateElement) {
      const hookedCreate = function(tagName, options) {
        const el = _origCreateElement.call(this, tagName, options);
        // We cannot access contentWindow here because it's not yet in the DOM.
        // We will rely on the DOM insert hooks. But we can attach a MutationObserver
        // to catch iframes created via innerHTML that bypass appendChild explicitly.
        if (tagName && String(tagName).toLowerCase() === 'iframe') {
           // We place a tiny listener that runs as soon as it's loaded, 
           // though the node insert hook is the primary synchronous defense.
           try {
              el.addEventListener('load', function() {
                 _injectIntoWindow(el.contentWindow);
              }, { once: true });
           } catch(e) {}
        }
        return el;
      };
      self.__pbrowser_cloak(hookedCreate, 'function createElement() { [native code] }');
      Document.prototype.createElement = hookedCreate;
    }

    // 3. Fallback: MutationObserver for innerHTML or edge cases
    try {
      const _mutObserver = new MutationObserver((mutations) => {
        for (const mut of mutations) {
          if (mut.addedNodes && mut.addedNodes.length > 0) {
            for (const node of mut.addedNodes) {
              if (node.tagName && String(node.tagName).toLowerCase() === 'iframe') {
                _injectIntoWindow(node.contentWindow);
              } else if (node.querySelectorAll) {
                // Check if an iframe was inserted as a child of the added node
                try {
                  const frames = node.querySelectorAll('iframe');
                  frames.forEach(f => _injectIntoWindow(f.contentWindow));
                } catch(e){}
              }
            }
          }
        }
      });
      _mutObserver.observe(document.documentElement, { childList: true, subtree: true });
    } catch(e) {}

    // 4. Keep the lazy contentWindow property descriptor proxy as a fallback
    const origContentWindowDesc = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'contentWindow');
    if (origContentWindowDesc && origContentWindowDesc.get) {
      const spoofedGetCW = function() {
        const cw = origContentWindowDesc.get.call(this);
        if (cw && !cw.__pbrowser_injected_secure) {
           _injectIntoWindow(cw);
        }
        return cw;
      };
      self.__pbrowser_cloak(spoofedGetCW, 'function get contentWindow() { [native code] }');
      Object.defineProperty(HTMLIFrameElement.prototype, 'contentWindow', {
          get: spoofedGetCW, enumerable: true, configurable: true
      });
    }

    // 4. contentDocument property descriptor proxy
    const origContentDocDesc = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'contentDocument');
    if (origContentDocDesc && origContentDocDesc.get) {
      const spoofedGetCD = function() {
        // Just getting the document can trigger context creation, so we check contentWindow
        try {
           const cw = origContentWindowDesc.get.call(this);
           if (cw && !cw.__pbrowser_injected_secure) {
              _injectIntoWindow(cw);
           }
        } catch(e){}
        return origContentDocDesc.get.call(this);
      };
      self.__pbrowser_cloak(spoofedGetCD, 'function get contentDocument() { [native code] }');
      Object.defineProperty(HTMLIFrameElement.prototype, 'contentDocument', {
          get: spoofedGetCD, enumerable: true, configurable: true
      });
    }

    // 6. contentDocument descriptor proxy for HTMLObjectElement
    const origObjDocDesc = Object.getOwnPropertyDescriptor(HTMLObjectElement.prototype, 'contentDocument');
    if (origObjDocDesc && origObjDocDesc.get) {
      const spoofedObjGetCD = function() {
        try {
           const cw = this.contentWindow;
           if (cw && !cw.__pbrowser_injected_secure) {
              _injectIntoWindow(cw);
           }
        } catch(e){}
        return origObjDocDesc.get.call(this);
      };
      self.__pbrowser_cloak(spoofedObjGetCD, 'function get contentDocument() { [native code] }');
      Object.defineProperty(HTMLObjectElement.prototype, 'contentDocument', {
          get: spoofedObjGetCD, enumerable: true, configurable: true
      });
    }

  } catch(e) {}
})();
''';
  }
}
