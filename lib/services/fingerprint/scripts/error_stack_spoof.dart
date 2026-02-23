import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for Error Stack Trace Normalization.
/// Android V8/WebView produces slightly different Error.prototype.stack
/// formatting vs Chrome Desktop. Intercepts Error to normalize stack format.
class ErrorStackSpoof {
  static String generate(FingerprintConfig config) {
    return r'''
// ===== ERROR STACK TRACE NORMALIZATION =====
// Android V8 stack traces differ from Desktop Chrome in whitespace/format.
// Normalize to Chrome Desktop "    at FunctionName (file:line:col)" format.
(() => {
  try {
    const _origErrorProto = Error.prototype;
    const _origGetter = Object.getOwnPropertyDescriptor(_origErrorProto, 'stack');

    // Normalize a single stack string to Chrome Desktop format
    const normalizeStack = (stack) => {
      if (typeof stack !== 'string') return stack;

      return stack
        // Ensure "at" lines have exactly 4 spaces indent (V8 sometimes uses tabs)
        .replace(/^\t+at /gm, '    at ')
        // Normalize inconsistent spacing around 'at'
        .replace(/^(\s*)at\s+/gm, '    at ')
        // Strip Android-specific jni: or java: frames
        .replace(/^.*jni:.*$/gm, '')
        .replace(/^.*java\..*$/gm, '')
        // Remove blank lines left by stripping
        .replace(/\n{3,}/g, '\n\n')
        .trim();
    };

    if (_origGetter && _origGetter.get) {
      const _origGet = _origGetter.get;
      const _spoofedGet = function() {
        const raw = _origGet.call(this);
        try { return normalizeStack(raw); } catch(e) { return raw; }
      };
      window.__pbrowser_cloak(_spoofedGet, 'function get stack() { [native code] }');
      Object.defineProperty(Error.prototype, 'stack', {
        get: _spoofedGet,
        set: _origGetter.set,
        configurable: true,
        enumerable: _origGetter.enumerable
      });
    }

    // Also suppress V8-specific Error.captureStackTrace detection
    // FingerprintJS Pro checks for this as a V8 probe
    if (Error.captureStackTrace) {
      const _origCST = Error.captureStackTrace;
      const _spoofedCST = function(obj, constr) {
        _origCST(obj, constr);
        if (obj && obj.stack) {
          try { obj.stack = normalizeStack(obj.stack); } catch(e) {}
        }
      };
      window.__pbrowser_cloak(_spoofedCST, 'function captureStackTrace() { [native code] }');
      Error.captureStackTrace = _spoofedCST;
    }

  } catch(e) {}
})();
''';
  }
}
