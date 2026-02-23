import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/navigator_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/canvas_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webgl_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webrtc_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/audio_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/timezone_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/utils.dart';

/// Orchestrates all fingerprint spoofing scripts
class FingerprintInjector {
  final FingerprintConfig config;
  final bool lightweight;
  
  const FingerprintInjector(
    this.config, {
    this.lightweight = false,
  });
  
  /// Generate complete injection script with native cloaking
  String generateInjectionScript() {
    return '''
(function() {
  'use strict';
  
  // Prevent re-injection
  if (window.__pbrowser_injected) return;
  window.__pbrowser_injected = true;
  
  // Initialize global cloaking BEFORE any spoofing runs
  \${NativeUtils.initCloaking()}
  
  // Install all spoofing modules with native cloaking
  \${NavigatorSpoof.generate(config)}
  
  \${CanvasSpoof.generate(config)}
  
  \${WebGLSpoof.generate(config)}
  
  \${WebRTCSpoof.generate(config)}
  
  \${AudioSpoof.generate(config)}
  
  \${TimezoneSpoof.generate(config)}
  
  // Iframe Shield - Propagate spoofing to child frames dynamically
  (() => {
    try {
      const originalContentWindow = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'contentWindow').get;
      const proxyContentWindow = new Proxy(originalContentWindow, {
        apply(target, thisArg, args) {
          const cw = Reflect.apply(target, thisArg, args);
          if (cw && !cw.__pbrowser_injected) {
            try {
              cw.__pbrowser_injected = true;
              Object.defineProperty(cw, 'navigator', {
                get: () => navigator
              });
            } catch(e) {}
          }
          return cw;
        }
      });
      window.__pbrowser_cloak(proxyContentWindow, Function.prototype.toString.call(originalContentWindow));
      Object.defineProperty(HTMLIFrameElement.prototype, 'contentWindow', {
        get: proxyContentWindow,
        set: undefined,
        enumerable: true,
        configurable: true
      });
    } catch(e) {}
  })();
  
  // Final protection layer
  \${NativeUtils.preventNavigatorDetection()}
  
  console.log('[PBrowser] 🛡️ Fingerprint protection active (hardened)');
})();
''';
  }
  
  /// Generate minimal metadata override (faster for non-critical pages)
  String generateLightweightScript() {
    return '''
(function() {
  'use strict';
  
  if (window.__pbrowser_injected) return;
  window.__pbrowser_injected = true;
  
  \${NativeUtils.initCloaking()}
  \${NavigatorSpoof.generate(config)}
  \${WebRTCSpoof.generate(config)}
})();
''';
  }
}
