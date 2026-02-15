import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/navigator_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/canvas_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webgl_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webrtc_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/audio_spoof.dart';

/// Main fingerprint injection orchestrator
/// Combines all spoofing scripts into a single injectable JavaScript
class FingerprintInjector {
  final FingerprintConfig config;
  
  FingerprintInjector(this.config);
  
  /// Generate complete injection script
  /// This should be executed as early as possible during page load
  String generateInjectionScript() {
    return '''
(function() {
  'use strict';
  
  // Prevent re-injection
  if (window.__pbrowser_injected) return;
  window.__pbrowser_injected = true;
  
  ${NavigatorSpoof.generate(config)}
  
  ${CanvasSpoof.generate(config)}
  
  ${WebGLSpoof.generate(config)}
  
  ${WebRTCSpoof.generate(config)}
  
  ${AudioSpoof.generate(config)}
  
  console.log('[PBrowser] Fingerprint protection active');
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
