import 'package:sec_tunnel/models/fingerprint_config.dart';

class ContextEngine {
  static String generate(FingerprintConfig config) {
    return '''
// ===== CROSS-CONTEXT CONSISTENCY ENGINE =====
(() => {
  try {
    // Cross-context validation: compare prototypes and navigators
    const validateContext = (targetWin, contextName) => {
      try {
        if (!targetWin.navigator) return;
        const mainNav = (typeof window !== 'undefined' ? window : self).navigator.userAgent;
        const targetNav = targetWin.navigator.userAgent;
        if (mainNav !== targetNav) {
          console.error(`[CONTEXT] Consistency mismatch detected in \${contextName}!`);
        } else {
          console.debug(`[CONTEXT] consistency verified`);
        }
      } catch(e) {}
    };

    // Expose for iframe guard and worker to call
    const globalScope = (typeof window !== 'undefined' ? window : self);
    globalScope.__pbrowser_validate_context = validateContext;

    // 6. PROTOTYPE CONSISTENCY
    // Ensure navigator.__proto__ chain matches across contexts
    if (globalScope.navigator && globalScope.Navigator) {
       try {
         Object.setPrototypeOf(globalScope.navigator, globalScope.Navigator.prototype);
       } catch(e) {}
    }

    // 8. MESSAGE CHANNEL INTEGRATION
    const _origPostMessage = globalScope.postMessage;
    if (_origPostMessage) {
      globalScope.__pbrowser_cloak(_origPostMessage, globalScope, 'postMessage');
      globalScope.postMessage = function(message, targetOrigin, transfer) {
         // Intercept structured clone or message leaking real navigator values if needed
         return _origPostMessage.call(this, message, targetOrigin, transfer);
      };
      globalScope.__pbrowser_cloak(globalScope.postMessage, globalScope, 'postMessage');
    }
    
    // 7. STORAGE & CACHE CONSISTENCY
    // Storage methods are already overridden in storage_spoof.dart
    // Here we ensure the prototypes match to prevent detection via prototype checking
    if (globalScope.Storage) {
       try { Object.freeze(globalScope.Storage.prototype); } catch(e) {}
    }
  } catch(e) {}
})();
''';
  }
}
