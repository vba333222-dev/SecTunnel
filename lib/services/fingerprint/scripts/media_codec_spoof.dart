import 'package:SecTunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Media Codec Fingerprinting Spoofing.
/// Overrides canPlayType and MediaSource.isTypeSupported with per-OS codec dictionaries
/// matching Chrome Desktop codec support profiles precisely.
class MediaCodecSpoof {
  static String generate(FingerprintConfig config) {
    final platform = config.platform.toLowerCase();
    final isWindows = platform.contains('win');
    final isMac     = platform.contains('mac');  // covers 'macintel', 'mac arm', etc.
    final isDesktop = isWindows || isMac ||
        platform.contains('linux x86_64') ||
        platform.contains('linux x64');

    if (!isDesktop) {
      return '// [MediaCodecSpoof] Mobile profile — codec capabilities intact.';
    }

    return '''
// ===== MEDIA CODEC FINGERPRINTING SPOOFING =====
(() => {
  try {

    // ================================================================
    // CODEC DICTIONARIES
    // Format: { pattern (regex), result: 'probably'|'maybe'|'' }
    // Evaluated in order — first match wins.
    // ================================================================

    const FORCE_PROBABLY = [
      // H.264 / AVC — universally supported on all desktop Chrome
      /video\\/mp4.*avc1\\.42/i,
      /video\\/mp4.*avc1\\.4D/i,
      /video\\/mp4.*avc1\\.64/i,
      /video\\/mp4.*avc1/i,
      // AAC audio
      /audio\\/mp4.*mp4a\\.40\\.2/i,
      /audio\\/mp4.*mp4a\\.40/i,
      /audio\\/aac/i,
      // WebM VP8
      /video\\/webm.*vp8/i,
      /audio\\/webm.*vorbis/i,
      // VP9
      /video\\/webm.*vp9/i,
      // Opus
      /audio\\/webm.*opus/i,
      /audio\\/ogg.*opus/i,
      // MP3
      /audio\\/mpeg/i,
      /audio\\/mp3/i,
      // Ogg Vorbis
      /audio\\/ogg.*vorbis/i,
      // FLAC
      /audio\\/flac/i,
      // WAV
      /audio\\/wav/i,
      /audio\\/x-wav/i,
    ];

    const FORCE_MAYBE = [
      // H.265 / HEVC — desktop Chrome returns 'maybe', not 'probably'
      /video\\/mp4.*hev1/i,
      /video\\/mp4.*hvc1/i,
      // AV1 — supported but 'maybe' on some hardware
      /video\\/webm.*av01/i,
      /video\\/mp4.*av01/i,
    ];

    // Codecs exclusive to Android / mobile hardware — always block on Desktop
    const FORCE_BLOCK = [
      // Android's hardware video encoder formats
      /video\\/3gpp/i,
      /video\\/3gpp2/i,
      /video\\/x-matroska/i,
      // AMR audio (GSM voice codec — strictly mobile)
      /audio\\/amr/i,
      /audio\\/3gpp/i,
      /audio\\/x-amr/i,
      // MIDI (not supported in Chrome Desktop)
      /audio\\/midi/i,
      /audio\\/x-midi/i,
    ];

    // ================================================================
    // 1. HTMLMediaElement.prototype.canPlayType
    // ================================================================
    const origCanPlayType = HTMLMediaElement.prototype.canPlayType;
    const spoofedCanPlayType = function(type) {
      if (!type) return '';
      const t = String(type);

      for (const pattern of FORCE_BLOCK) {
        if (pattern.test(t)) return '';
      }
      for (const pattern of FORCE_PROBABLY) {
        if (pattern.test(t)) return 'probably';
      }
      for (const pattern of FORCE_MAYBE) {
        if (pattern.test(t)) return 'maybe';
      }

      // Passthrough — let the native engine answer for anything not in our dict
      return origCanPlayType.call(this, type);
    };
    window.__pbrowser_cloak(spoofedCanPlayType, 'function canPlayType() { [native code] }');
    HTMLMediaElement.prototype.canPlayType = spoofedCanPlayType;

    // ================================================================
    // 2. MediaSource.isTypeSupported (static method)
    // ================================================================
    if (typeof MediaSource !== 'undefined' && MediaSource.isTypeSupported) {
      const origIsTypeSupported = MediaSource.isTypeSupported.bind(MediaSource);
      const spoofedIsTypeSupported = function(type) {
        if (!type) return false;
        const t = String(type);

        for (const pattern of FORCE_BLOCK) {
          if (pattern.test(t)) return false;
        }
        for (const pattern of FORCE_PROBABLY) {
          if (pattern.test(t)) return true;
        }
        for (const pattern of FORCE_MAYBE) {
          // MediaSource.isTypeSupported returns boolean — 'maybe' maps to true
          if (pattern.test(t)) return true;
        }
        return origIsTypeSupported(type);
      };
      window.__pbrowser_cloak(spoofedIsTypeSupported, 'function isTypeSupported() { [native code] }');
      try {
        Object.defineProperty(MediaSource, 'isTypeSupported', {
          value: spoofedIsTypeSupported,
          writable: false, enumerable: true, configurable: true
        });
      } catch(e) {
        MediaSource.isTypeSupported = spoofedIsTypeSupported;
      }
    }

    // ================================================================
    // 3. navigator.mediaCapabilities.decodingInfo  (Chrome M82+)
    // Intercept to prevent codec profiling via the modern Capabilities API
    // ================================================================
    if (navigator.mediaCapabilities && navigator.mediaCapabilities.decodingInfo) {
      const origDecodingInfo = navigator.mediaCapabilities.decodingInfo.bind(navigator.mediaCapabilities);
      const spoofedDecodingInfo = function(config) {
        return origDecodingInfo(config).then(result => {
          // For blocked mobile codecs, report unsupported
          if (config && config.video && config.video.contentType) {
            for (const pattern of FORCE_BLOCK) {
              if (pattern.test(config.video.contentType)) {
                return { supported: false, smooth: false, powerEfficient: false };
              }
            }
          }
          return result;
        });
      };
      window.__pbrowser_cloak(spoofedDecodingInfo, 'function decodingInfo() { [native code] }');
      try {
        Object.defineProperty(navigator.mediaCapabilities, 'decodingInfo', {
          value: spoofedDecodingInfo,
          writable: false, enumerable: true, configurable: true
        });
      } catch(e) {
        navigator.mediaCapabilities.decodingInfo = spoofedDecodingInfo;
      }
    }

  } catch(e) {}
})();
''';
  }
}
