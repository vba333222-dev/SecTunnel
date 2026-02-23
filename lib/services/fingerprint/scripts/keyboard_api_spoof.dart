import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for navigator.keyboard API Desktop Stub.
/// Chrome Desktop exposes navigator.keyboard with getLayoutMap() Promise.
/// Android WebView has no keyboard API — its absence is a detection signal.
class KeyboardApiSpoof {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isDesktop = platform.contains('win') ||
        platform.contains('mac') ||
        platform.contains('linux');

    if (!isDesktop) {
      return '// [KeyboardApiSpoof] Mobile profile — keyboard API absent is expected.';
    }

    // Provide a QWERTY layout map consistent with the profile language
    final lang = config.language.toLowerCase();
    final layoutId = lang.startsWith('id') ? 'id' :
                     lang.startsWith('ja') ? 'ja-JP-106' :
                     lang.startsWith('ko') ? 'ko-KR-101' :
                     lang.startsWith('zh') ? 'zh-CN-pinyin' :
                     lang.startsWith('de') ? 'de-DE-qwertz' :
                     lang.startsWith('fr') ? 'fr-FR-azerty' : 'en-US';

    return '''
// ===== NAVIGATOR.KEYBOARD API DESKTOP STUB =====
// Chrome Desktop exposes navigator.keyboard — absent on Android WebView (detection signal)
(() => {
  try {
    if (navigator.keyboard) return; // Already present, nothing to do

    // Minimal QWERTY layout entries (a subset is enough to pass truthiness checks)
    const QWERTY_ENTRIES = [
      ['KeyA','a'], ['KeyB','b'], ['KeyC','c'], ['KeyD','d'], ['KeyE','e'],
      ['KeyF','f'], ['KeyG','g'], ['KeyH','h'], ['KeyI','i'], ['KeyJ','j'],
      ['KeyK','k'], ['KeyL','l'], ['KeyM','m'], ['KeyN','n'], ['KeyO','o'],
      ['KeyP','p'], ['KeyQ','q'], ['KeyR','r'], ['KeyS','s'], ['KeyT','t'],
      ['KeyU','u'], ['KeyV','v'], ['KeyW','w'], ['KeyX','x'], ['KeyY','y'],
      ['KeyZ','z'], ['Digit0','0'], ['Digit1','1'], ['Digit2','2'],
      ['Digit3','3'], ['Digit4','4'], ['Digit5','5'], ['Digit6','6'],
      ['Digit7','7'], ['Digit8','8'], ['Digit9','9'],
      ['Space',' '], ['Enter',''], ['Backspace',''],
    ];

    // Build a fake KeyboardLayoutMap (Map-like, iterable, has .get/.has/.keys/.entries)
    const layoutMap = new Map(QWERTY_ENTRIES);
    Object.defineProperty(layoutMap, 'size',
      { value: QWERTY_ENTRIES.length, enumerable: true, configurable: true });

    const keyboardStub = {
      getLayoutMap: function() {
        return Promise.resolve(layoutMap);
      },
      lock:   function() { return Promise.resolve(); },
      unlock: function() {},
    };

    window.__pbrowser_cloak(keyboardStub.getLayoutMap,
      'function getLayoutMap() { [native code] }');
    window.__pbrowser_cloak(keyboardStub.lock,
      'function lock() { [native code] }');

    try {
      Object.defineProperty(Navigator.prototype, 'keyboard', {
        get: function() { return keyboardStub; },
        configurable: true, enumerable: true
      });
    } catch(e) {
      try { navigator.keyboard = keyboardStub; } catch(e2) {}
    }

  } catch(e) {}
})();
''';
  }
}
