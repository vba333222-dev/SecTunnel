import 'package:SecTunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Web Speech API Voices Spoofing.
/// Intercepts speechSynthesis.getVoices() to return OS-appropriate TTS
/// voice lists (Microsoft on Windows, Apple on macOS), masking Android TTS.
class SpeechSynthesisSpoof {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isWindows = platform.contains('win');
    final isMac = platform.contains('mac');

    // For mobile profiles that don't claim to be Desktop, leave voices intact
    final isDesktop = isWindows || isMac ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    if (!isDesktop) {
      return '// [SpeechSynthesisSpoof] Mobile profile — TTS voices intact.';
    }

    final voicesJson = isWindows
        ? _windowsVoicesJson
        : isMac
            ? _macVoicesJson
            : _linuxVoicesJson;

    return '''
// ===== SPEECH SYNTHESIS VOICES SPOOFING =====
(() => {
  try {
    if (!window.speechSynthesis) return;

    // Build mock SpeechSynthesisVoice objects
    const makeVoice = (name, lang, localService, isDefault, voiceURI) => {
      const v = Object.create(
        typeof SpeechSynthesisVoice !== 'undefined'
          ? SpeechSynthesisVoice.prototype
          : Object.prototype
      );
      Object.defineProperty(v, 'name',         { value: name,         enumerable: true, configurable: true });
      Object.defineProperty(v, 'lang',         { value: lang,         enumerable: true, configurable: true });
      Object.defineProperty(v, 'localService', { value: localService, enumerable: true, configurable: true });
      Object.defineProperty(v, 'default',      { value: isDefault,    enumerable: true, configurable: true });
      Object.defineProperty(v, 'voiceURI',     { value: voiceURI,     enumerable: true, configurable: true });
      return v;
    };

    // OS-specific voice definitions
    const VOICE_DEFS = $voicesJson;

    const spoofedVoices = VOICE_DEFS.map(d =>
      makeVoice(d.name, d.lang, d.local, d.default, d.uri)
    );

    // --- Override getVoices() ---
    const originalGetVoices = window.speechSynthesis.getVoices.bind(window.speechSynthesis);
    const spoofedGetVoices  = function() { return spoofedVoices; };

    window.__pbrowser_cloak(spoofedGetVoices, 'function getVoices() { [native code] }');
    try {
      Object.defineProperty(window.speechSynthesis, 'getVoices', {
        value: spoofedGetVoices,
        writable: false, enumerable: true, configurable: true
      });
    } catch(e) {
      window.speechSynthesis.getVoices = spoofedGetVoices;
    }

    // --- Intercept onvoiceschanged ---
    // Sites listen to the event to trigger getVoices().
    // We fire it immediately so the spoofed list is returned on first call.
    const originalOnVC = Object.getOwnPropertyDescriptor(
      window.SpeechSynthesis ? SpeechSynthesis.prototype : window.speechSynthesis,
      'onvoiceschanged'
    );

    // Dispatch voiceschanged once after script settles
    setTimeout(() => {
      try {
        const event = new Event('voiceschanged');
        window.speechSynthesis.dispatchEvent(event);
      } catch(e) {}
    }, 0);

  } catch(e) {}
})();
''';
  }

  // ─── Windows Microsoft TTS Voices ────────────────────────────────────────
  static const _windowsVoicesJson = '''[
    { "name": "Microsoft David - English (United States)",     "lang": "en-US", "local": true,  "default": true,  "uri": "Microsoft David - English (United States)" },
    { "name": "Microsoft Mark - English (United States)",      "lang": "en-US", "local": true,  "default": false, "uri": "Microsoft Mark - English (United States)" },
    { "name": "Microsoft Zira - English (United States)",      "lang": "en-US", "local": true,  "default": false, "uri": "Microsoft Zira - English (United States)" },
    { "name": "Microsoft George - English (United Kingdom)",   "lang": "en-GB", "local": true,  "default": false, "uri": "Microsoft George - English (United Kingdom)" },
    { "name": "Microsoft Hazel - English (United Kingdom)",    "lang": "en-GB", "local": true,  "default": false, "uri": "Microsoft Hazel - English (United Kingdom)" },
    { "name": "Microsoft Susan - English (United Kingdom)",    "lang": "en-GB", "local": true,  "default": false, "uri": "Microsoft Susan - English (United Kingdom)" },
    { "name": "Microsoft Heera - English (India)",             "lang": "en-IN", "local": true,  "default": false, "uri": "Microsoft Heera - English (India)" },
    { "name": "Microsoft Ravi - English (India)",              "lang": "en-IN", "local": true,  "default": false, "uri": "Microsoft Ravi - English (India)" },
    { "name": "Microsoft James - English (Australia)",         "lang": "en-AU", "local": true,  "default": false, "uri": "Microsoft James - English (Australia)" },
    { "name": "Microsoft Catherine - English (Australia)",     "lang": "en-AU", "local": true,  "default": false, "uri": "Microsoft Catherine - English (Australia)" },
    { "name": "Microsoft Guillaume - French (France)",         "lang": "fr-FR", "local": true,  "default": false, "uri": "Microsoft Guillaume - French (France)" },
    { "name": "Microsoft Hortense - French (France)",          "lang": "fr-FR", "local": true,  "default": false, "uri": "Microsoft Hortense - French (France)" },
    { "name": "Microsoft Stefan - German (Germany)",           "lang": "de-DE", "local": true,  "default": false, "uri": "Microsoft Stefan - German (Germany)" },
    { "name": "Microsoft Hedda - German (Germany)",            "lang": "de-DE", "local": true,  "default": false, "uri": "Microsoft Hedda - German (Germany)" },
    { "name": "Microsoft Andika - Indonesian (Indonesia)",     "lang": "id-ID", "local": true,  "default": false, "uri": "Microsoft Andika - Indonesian (Indonesia)" }
  ]''';

  // ─── macOS Apple TTS Voices ──────────────────────────────────────────────
  static const _macVoicesJson = '''[
    { "name": "Alex",    "lang": "en-US", "local": true,  "default": true,  "uri": "com.apple.speech.synthesis.voice.Alex" },
    { "name": "Allison", "lang": "en-US", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Allison" },
    { "name": "Ava",     "lang": "en-US", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Ava" },
    { "name": "Fred",    "lang": "en-US", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Fred" },
    { "name": "Samantha","lang": "en-US", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Samantha" },
    { "name": "Serena",  "lang": "en-GB", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Serena" },
    { "name": "Daniel",  "lang": "en-GB", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Daniel" },
    { "name": "Karen",   "lang": "en-AU", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Karen" },
    { "name": "Amelie",  "lang": "fr-CA", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Amelie" },
    { "name": "Thomas",  "lang": "fr-FR", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Thomas" },
    { "name": "Anna",    "lang": "de-DE", "local": true,  "default": false, "uri": "com.apple.speech.synthesis.voice.Anna" }
  ]''';

  // ─── Linux eSpeak-NG Voices ───────────────────────────────────────────────
  static const _linuxVoicesJson = '''[
    { "name": "Google US English",            "lang": "en-US", "local": false, "default": true,  "uri": "Google US English" },
    { "name": "Google UK English Female",     "lang": "en-GB", "local": false, "default": false, "uri": "Google UK English Female" },
    { "name": "Google UK English Male",       "lang": "en-GB", "local": false, "default": false, "uri": "Google UK English Male" },
    { "name": "Google Deutsch",               "lang": "de-DE", "local": false, "default": false, "uri": "Google Deutsch" },
    { "name": "Google français",              "lang": "fr-FR", "local": false, "default": false, "uri": "Google français" },
    { "name": "Google Bahasa Indonesia",      "lang": "id-ID", "local": false, "default": false, "uri": "Google Bahasa Indonesia" }
  ]''';
}
