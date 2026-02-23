import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/services/fingerprint/scripts/navigator_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/canvas_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webgl_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webrtc_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/audio_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/timezone_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/battery_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/font_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/webview_scrubber.dart';
import 'package:pbrowser/services/fingerprint/scripts/domrect_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/hardware_sensor_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/media_devices_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/worker_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/window_metrics_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/matchmedia_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/hardware_api_polyfill.dart';
import 'package:pbrowser/services/fingerprint/scripts/timing_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/uach_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/speech_synthesis_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/network_info_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/font_metrics_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/media_codec_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/storage_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/screen_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/error_stack_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/geolocation_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/keyboard_api_spoof.dart';
import 'package:pbrowser/services/fingerprint/scripts/service_worker_guard.dart';
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

  // L-1: Session-level entropy — same profile fingerprint differs slightly each session
  \${NativeUtils.initSessionEntropy(config.canvasNoiseSalt.hashCode.abs())}

  // L-3 guard: if cloak failed for any reason, abort rather than crash all modules
  if (typeof window.__pbrowser_cloak !== 'function') return;
  
  // Wipe out Android/Flutter WebView leaks immediately
  \${WebviewScrubber.generate(config)}
  
  // Install all spoofing modules with native cloaking
  \${NavigatorSpoof.generate(config)}

  // Align navigator.userAgentData (UA-CH API) with spoofed userAgent
  \${UACHSpoof.generate(config)}

  // Add navigator.keyboard Desktop stub (absent on Android WebView)
  \${KeyboardApiSpoof.generate(config)}

  // Spoof Web Speech API voice list to match OS TTS engine
  \${SpeechSynthesisSpoof.generate(config)}

  // Strip mobile-only NetworkInformation properties (.type/.saveData)
  \${NetworkInfoSpoof.generate(config)}

  // Mask Android Roboto kerning via deterministc font metric deltas
  \${FontMetricsSpoof.generate(config)}

  // Enforce Desktop codec capability table (canPlayType / isTypeSupported)
  \${MediaCodecSpoof.generate(config)}

  // Inject File Picker API stubs and spoof storage quota
  \${StorageSpoof.generate(config)}

  // Normalize screen color/pixel depth and dimensions (M-1 fix)
  \${ScreenSpoof.generate(config)}

  // Normalize Error.prototype.stack format to Chrome Desktop (H-2 fix)
  \${ErrorStackSpoof.generate(config)}
  
  // Conditionally strip mobile-only APIs for Desktop profiles
  \${HardwareSensorSpoof.generate(config)}

  // Spoof Geolocation API to return timezone-consistent coordinates
  \${GeolocationSpoof.generate(config)}
  
  // Spoof media device enumeration with deterministic desktop hardware IDs
  \${MediaDevicesSpoof.generate(config)}
  
  // Shield Worker/SharedWorker sandboxes from leaking real navigator values
  \${WorkerSpoof.generate(config)}

  // Fix window frame metrics: outerWidth > innerWidth (desktop browser chrome)
  \${WindowMetricsSpoof.generate(config)}

  // Spoof CSS pointer/hover media queries to match Desktop input model
  \${MatchMediaSpoof.generate(config)}

  // Inject Desktop hardware API stubs (USB, Bluetooth, HID, Serial, Keyboard)
  \${HardwareApiPolyfill.generate(config)}

  // Fuzz timing APIs to defeat Proxy-overhead timing comparison attacks
  \${TimingSpoof.generate(config)}
  
  \${CanvasSpoof.generate(config)}
  
  \${WebGLSpoof.generate(config)}
  
  \${WebRTCSpoof.generate(config)}
  
  \${AudioSpoof.generate(config)}
  
  \${TimezoneSpoof.generate(config)}
  
  \${BatterySpoof.generate(config)}
  
  \${FontSpoof.generate(config)}

  \${DOMRectSpoof.generate(config)}

  // scrollX / scrollY non-zero: fresh WebView always starts at 0,0 — a detection signal
  // Spoof to a plausible small scroll offset that looks like the user has scrolled a bit
  (() => {
    try {
      const _seed   = ${config.canvasNoiseSalt.hashCode.abs()};
      const _scrollX = 0;             // Usually 0 horizontally on Desktop
      const _scrollY = 4 + (_seed % 15); // 4–18 px — natural page entry scroll
      const _defWinProp = (prop, val) => {
        try {
          Object.defineProperty(window, prop, {
            get: function() { return val; }, configurable: true, enumerable: true
          });
        } catch(e) {}
      };
      _defWinProp('scrollX', _scrollX);
      _defWinProp('scrollY', _scrollY);
      _defWinProp('pageXOffset', _scrollX);
      _defWinProp('pageYOffset', _scrollY);
    } catch(e) {}
  })();
  
  // Iframe Shield — re-inject spoofing into same-origin child frames
  // (Cross-origin frames cannot be modified — that's correct and expected)
  (() => {
    try {
      const origContentDocGetter = Object.getOwnPropertyDescriptor(
        HTMLIFrameElement.prototype, 'contentDocument'
      );
      if (!origContentDocGetter || !origContentDocGetter.get) return;

      Object.defineProperty(HTMLIFrameElement.prototype, 'contentDocument', {
        get: function() {
          const doc = origContentDocGetter.get.call(this);
          if (doc && !doc.__pbrowser_injected) {
            try {
              // Only works for same-origin frames (cross-origin will throw)
              const script = doc.createElement('script');
              script.textContent = window.__pbrowser_frame_script || '';
              (doc.head || doc.documentElement).appendChild(script);
              script.remove();
            } catch(e) {} // silently ignore cross-origin SecurityError
          }
          return doc;
        },
        enumerable: true,
        configurable: true
      });
    } catch(e) {}
  })();
  
  // Protect Service Worker scope from real navigator leaks (H-1 fix)
  \${ServiceWorkerGuard.generate(config)}

  // Final protection layer
  \${NativeUtils.preventNavigatorDetection()}

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
  if (typeof window.__pbrowser_cloak !== 'function') return;

  // Core identity spoof
  \${NavigatorSpoof.generate(config)}
  // UA-CH alignment
  \${UACHSpoof.generate(config)}
  // WebRTC leak prevention (critical even on light pages)
  \${WebRTCSpoof.generate(config)}
  // Timing API precision reduction
  \${TimingSpoof.generate(config)}
  // Storage quota (some light pages probe this)
  \${StorageSpoof.generate(config)}
  // Permissions API hardening
  // (prevents TypeError on desktop-only permission queries)
  // Already included in NavigatorSpoof
})();
''';
  }
}
