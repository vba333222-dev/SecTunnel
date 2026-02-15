import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for WebGL fingerprint spoofing
class WebGLSpoof {
  static String generate(FingerprintConfig config) {
    final vendor = _escapeJs(config.webglConfig.vendor);
    final renderer = _escapeJs(config.webglConfig.renderer);
    
    return '''
// ===== WEBGL SPOOFING =====
(() => {
  const getParameter = WebGLRenderingContext.prototype.getParameter;
  
  WebGLRenderingContext.prototype.getParameter = function(parameter) {
    // UNMASKED_VENDOR_WEBGL
    if (parameter === 37445) {
      return '$vendor';
    }
    
    // UNMASKED_RENDERER_WEBGL
    if (parameter === 37446) {
      return '$renderer';
    }
    
    return getParameter.apply(this, arguments);
  };
  
  // Also override for WebGL2
  if (typeof WebGL2RenderingContext !== 'undefined') {
    const getParameter2 = WebGL2RenderingContext.prototype.getParameter;
    
    WebGL2RenderingContext.prototype.getParameter = function(parameter) {
      if (parameter === 37445) {
        return '$vendor';
      }
      if (parameter === 37446) {
        return '$renderer';
      }
      return getParameter2.apply(this, arguments);
    };
  }
})();
''';
  }
  
  static String _escapeJs(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }
}
