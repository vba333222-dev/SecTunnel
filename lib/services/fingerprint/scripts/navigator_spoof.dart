import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for navigator spoofing
class NavigatorSpoof {
  static String generate(FingerprintConfig config) {
    return '''
// ===== NAVIGATOR SPOOFING =====
(() => {
  const originalDefineProperty = Object.defineProperty;
  
  // Override navigator.userAgent
  originalDefineProperty(navigator, 'userAgent', {
    get: () => '${_escapeJs(config.userAgent)}',
    configurable: true,
    enumerable: true
  });
  
  // Override navigator.platform
  originalDefineProperty(navigator, 'platform', {
    get: () => '${_escapeJs(config.platform)}',
    configurable: true,
    enumerable: true
  });
  
  // Override navigator.language
  originalDefineProperty(navigator, 'language', {
    get: () => '${_escapeJs(config.language)}',
    configurable: true,
    enumerable: true
  });
  
  // Override navigator.languages
  originalDefineProperty(navigator, 'languages', {
    get: () => ['${_escapeJs(config.language)}'],
    configurable: true,
    enumerable: true
  });
  
  // Override navigator.hardwareConcurrency
  originalDefineProperty(navigator, 'hardwareConcurrency', {
    get: () => ${config.hardwareConcurrency},
    configurable: true,
    enumerable: true
  });
  
  // Override navigator.deviceMemory
  if ('deviceMemory' in navigator) {
    originalDefineProperty(navigator, 'deviceMemory', {
      get: () => ${config.deviceMemory},
      configurable: true,
      enumerable: true
    });
  }
  
  // Override screen properties
  originalDefineProperty(screen, 'width', {
    get: () => ${config.screenResolution.width},
    configurable: true
  });
  
  originalDefineProperty(screen, 'height', {
    get: () => ${config.screenResolution.height},
    configurable: true
  });
  
  originalDefineProperty(screen, 'availWidth', {
    get: () => ${config.screenResolution.width},
    configurable: true
  });
  
  originalDefineProperty(screen, 'availHeight', {
    get: () => ${config.screenResolution.height - 40}, // Taskbar offset
    configurable: true
  });
  
  originalDefineProperty(screen, 'colorDepth', {
    get: () => ${config.screenResolution.colorDepth},
    configurable: true
  });
  
  originalDefineProperty(screen, 'pixelDepth', {
    get: () => ${config.screenResolution.colorDepth},
    configurable: true
  });
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
