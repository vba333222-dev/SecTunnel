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
  
  // Install all spoofing modules with native cloaking
  ${NavigatorSpoof.generate(config)}
  
  ${CanvasSpoof.generate(config)}
  
  ${WebGLSpoof.generate(config)}
  
  ${WebRTCSpoof.generate(config)}
  
  ${AudioSpoof.generate(config)}
  
  ${TimezoneSpoof.generate(config)}
  
  // Final protection layer
  ${NativeUtils.preventNavigatorDetection()}
  
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
  
  ${NavigatorSpoof.generate(config)}
  
  ${WebRTCSpoof.generate(config)}
})();
''';
  }
}
