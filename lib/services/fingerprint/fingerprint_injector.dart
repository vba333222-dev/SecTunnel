import 'package:SecTunnel/models/fingerprint_config.dart';
import 'package:SecTunnel/core/logging/logger.dart';
import 'package:SecTunnel/services/fingerprint/fingerprint_validator.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:SecTunnel/services/fingerprint/scripts/navigator_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/canvas_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/webgl_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/webrtc_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/audio_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/timezone_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/battery_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/font_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/webview_scrubber.dart';
import 'package:SecTunnel/services/fingerprint/scripts/domrect_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/hardware_sensor_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/media_devices_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/worker_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/window_metrics_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/matchmedia_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/hardware_api_polyfill.dart';
import 'package:SecTunnel/services/fingerprint/scripts/timing_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/uach_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/speech_synthesis_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/network_info_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/font_metrics_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/media_codec_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/storage_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/screen_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/error_stack_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/geolocation_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/keyboard_api_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/service_worker_guard.dart';
import 'package:SecTunnel/services/fingerprint/scripts/iframe_sandbox_guard.dart';
import 'package:SecTunnel/services/fingerprint/scripts/scrollbar_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/css_metrics_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/navigator_keys_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/intl_api_spoof.dart';
import 'package:SecTunnel/services/fingerprint/scripts/utils.dart';
import 'package:SecTunnel/services/fingerprint/scripts/behavior_engine.dart';
import 'package:SecTunnel/services/fingerprint/scripts/context_engine.dart';

/// Orchestrates all fingerprint spoofing scripts into a single coherent
/// injection payload. Validates cross-parameter consistency before generating.
///
/// Architecture:
///   FingerprintConfig (model) → FingerprintValidator (guard)
///     → FingerprintInjector (orchestrator) → 34 script modules → JS payload
class FingerprintInjector {
  final FingerprintConfig config;
  final bool lightweight;
  final AppLogger _log = AppLogger.instance;
  
  FingerprintInjector(
    this.config, {
    this.lightweight = false,
  });
  
  // ── Validation ──────────────────────────────────────────────────
  
  /// Validates the fingerprint config and logs results.
  /// Throws [FingerprintInconsistencyException] if config is invalid.
  void _validateAndLog() {
    _log.info(LogTag.system, '[FINGERPRINT] Config loaded — ${config.isDesktop ? "Desktop" : "Mobile"} profile (${config.platform})');
    
    // Hard-block injection if cross-parameter inconsistencies detected
    FingerprintValidator.assertValid(config);
    
    _log.info(LogTag.system, '[FINGERPRINT] Validation passed — all ${7} cross-checks OK');
  }
  
  // ── Full Injection ──────────────────────────────────────────────

  /// Generate complete injection script with native cloaking.
  /// All spoofing parameters are derived from the single [config] model.
  String generateInjectionScript() {
    _validateAndLog();
    _log.info(LogTag.system, '[FINGERPRINT] Applying modules — 11 phases, 34 script modules');
    _log.info(LogTag.system, '[FINGERPRINT] UA: ${_truncateUA(config.userAgent)}');
    final script = '''
// === CORE ANTI-DETECT WRAPPER ===
// Everything is wrapped in a secure IIFE to prevent global namespace pollution
(function(window) {
  'use strict';
  
  // Expose master script for cross-context propagation (workers, iframes)
  const globalScope = (typeof window !== 'undefined' ? window : self);
  globalScope.__pbrowser_master_script = arguments.callee.toString();

  // Prevent re-injection using a non-enumerable symbol or hidden property
  if (globalScope.__pbrowser_injected_secure) return;
  Object.defineProperty(globalScope, '__pbrowser_injected_secure', {
      value: true, enumerable: false, configurable: false, writable: false
  });
  
  // Initialize internal cloaking BEFORE any spoofing runs
  ${NativeUtils.initCloaking()}

  // L-1: Session-level entropy — same profile fingerprint differs slightly each session
  ${NativeUtils.initSessionEntropy(config.sessionBoundSeed.abs())}

  // L-3 guard: if cloak failed for any reason, abort rather than crash all modules
  if (typeof self.__pbrowser_cloak !== 'function') return;
  
  // ═══ PHASE 1: Environment Sanitization ═══════════════════════
  // Wipe out Android/Flutter WebView leaks immediately
  ${WebviewScrubber.generate(config)}
  
  // ═══ PHASE 2: Core Identity (navigator.*) ════════════════════
  // All navigator properties spoofed from unified DeviceFingerprint
  ${NavigatorSpoof.generate(config)}

  // Align navigator.userAgentData (UA-CH API) with spoofed userAgent
  ${UACHSpoof.generate(config)}

  // Add navigator.keyboard Desktop stub (absent on Android WebView)
  ${KeyboardApiSpoof.generate(config)}

  // Spoof Web Speech API voice list to match OS TTS engine
  ${SpeechSynthesisSpoof.generate(config)}

  // Strip mobile-only NetworkInformation properties (.type/.saveData)
  ${NetworkInfoSpoof.generate(config)}

  // ═══ PHASE 3: Visual Metrics (screen/DPR/window) ═════════════
  // Normalize screen color/pixel depth and dimensions
  ${ScreenSpoof.generate(config)}

  // Fix window frame metrics: outerWidth > innerWidth (desktop browser chrome)
  ${WindowMetricsSpoof.generate(config)}

  // Spoof CSS pointer/hover media queries to match Desktop input model
  ${MatchMediaSpoof.generate(config)}

  // ═══ PHASE 4: Canvas/WebGL/Audio Fingerprinting ══════════════
  ${CanvasSpoof.generate(config)}
  
  ${WebGLSpoof.generate(config)}
  
  ${AudioSpoof.generate(config)}

  // ═══ PHASE 5: Timezone/Locale/Intl ═══════════════════════════
  ${IntlApiSpoof.generate(config)}
  
  ${TimezoneSpoof.generate(config)}

  // ═══ PHASE 6: Network Isolation ══════════════════════════════
  // WebRTC leak prevention (IP exposure defense)
  ${WebRTCSpoof.generate(config)}

  // ═══ PHASE 7: Hardware/Sensor/API Surface ════════════════════
  // Conditionally strip mobile-only APIs for Desktop profiles
  ${HardwareSensorSpoof.generate(config)}

  // Spoof Geolocation API to return timezone-consistent coordinates
  ${GeolocationSpoof.generate(config)}
  
  // Spoof media device enumeration with deterministic desktop hardware IDs
  ${MediaDevicesSpoof.generate(config)}
  
  // Shield Worker/SharedWorker sandboxes from leaking real navigator values
  ${WorkerSpoof.generate(config)}

  // Inject Desktop hardware API stubs (USB, Bluetooth, HID, Serial, Keyboard)
  ${HardwareApiPolyfill.generate(config)}

  // ═══ PHASE 8: Timing/Entropy Defense ═════════════════════════
  // Fuzz timing APIs to defeat Proxy-overhead timing comparison attacks
  ${TimingSpoof.generate(config)}

  // ═══ PHASE 9: Font/DOM/CSS Fingerprinting ════════════════════
  // Mask Android Roboto kerning via deterministic font metric deltas
  ${FontMetricsSpoof.generate(config)}

  // Enforce Desktop codec capability table (canPlayType / isTypeSupported)
  ${MediaCodecSpoof.generate(config)}

  // Inject File Picker API stubs and spoof storage quota
  ${StorageSpoof.generate(config)}

  // Normalize Error.prototype.stack format to Chrome Desktop
  ${ErrorStackSpoof.generate(config)}

  ${BatterySpoof.generate(config)}
  
  ${FontSpoof.generate(config)}

  ${DOMRectSpoof.generate(config)}

  ${ScrollbarSpoof.generate(config)}
  
  // Cloak Android WebView specific CSS capabilities
  ${CSSMetricsSpoof.generate(config)}

  // ═══ PHASE 10: Scroll Position Entropy ═══════════════════════
  // scrollX / scrollY non-zero: fresh WebView always starts at 0,0
  (() => {
    try {
      const _seed   = ${config.sessionBoundSeed.abs()};
      const _scrollX = 0;
      const _scrollY = 4 + (_seed % 15);
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
  
  // ═══ PHASE 11: Context Isolation ═════════════════════════════
  // Prevents trackers from creating about:blank iframe and reading raw navigator
  ${IframeSandboxGuard.generate(config)}
  
  // Protect Service Worker scope from real navigator leaks
  ${ServiceWorkerGuard.generate(config)}

  // Lock the property iteration order for pure Desktop imitation
  ${NavigatorKeysSpoof.generate(config)}

  // ═══ PHASE 12: Behavioral Realism ════════════════════════════
  ${BehaviorEngine.generate(config)}

  // ═══ PHASE 13: Cross-Context Consistency ═════════════════════
  ${ContextEngine.generate(config)}

  // Final protection layer
  ${NativeUtils.preventNavigatorDetection()}

})(typeof window !== 'undefined' ? window : self);
''';

    _log.info(LogTag.system, '[FINGERPRINT] Injection complete — ${config.isDesktop ? "Desktop" : "Mobile"} (${config.screenResolution.width}x${config.screenResolution.height} @${config.devicePixelRatio}x, TZ: ${config.timezone})');
    return script;
  }
  
  // ── Lightweight Injection ───────────────────────────────────────

  /// Generate minimal metadata override (faster for non-critical pages)
  String generateLightweightScript() {
    _log.info(LogTag.system, '[FINGERPRINT] Applying lightweight profile');
    
    return '''
// === LIGHTWEIGHT ANTI-DETECT WRAPPER ===
(function(window) {
  'use strict';
  
  if (window.__pbrowser_injected_secure) return;
  Object.defineProperty(window, '__pbrowser_injected_secure', {
      value: true, enumerable: false, configurable: false, writable: false
  });
  
  ${NativeUtils.initCloaking()}
  if (typeof self.__pbrowser_cloak !== 'function') return;

  // Core identity spoof
  ${NavigatorSpoof.generate(config)}
  // UA-CH alignment
  ${UACHSpoof.generate(config)}
  // WebRTC leak prevention (critical even on light pages)
  ${WebRTCSpoof.generate(config)}
  // Timing API precision reduction
  ${TimingSpoof.generate(config)}
  // Storage quota (some light pages probe this)
  ${StorageSpoof.generate(config)}
})(window);
''';
  }

  // ── UserScript Generators ───────────────────────────────────────

  /// Wraps the heavy anti-detect fingerprint generator inside a strict
  /// Document_Start execution boundary to prevent early-boot leakage.
  List<UserScript> generateUserScripts() {
    return [
      UserScript(
        source: generateInjectionScript(),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: false,
      )
    ];
  }

  /// Wraps the lightweight anti-detect generator.
  List<UserScript> generateLightweightUserScripts() {
    return [
      UserScript(
        source: generateLightweightScript(),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: false,
      )
    ];
  }

  // ── Helpers ─────────────────────────────────────────────────────

  /// Truncates UA to first 60 chars for log readability.
  static String _truncateUA(String ua) {
    return ua.length > 60 ? '${ua.substring(0, 60)}…' : ua;
  }
}
