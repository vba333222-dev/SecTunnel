import 'package:SecTunnel/models/fingerprint_config.dart';

/// JavaScript code generator for Media Devices Enumeration Spoofing.
/// Intercepts navigator.mediaDevices.enumerateDevices() and returns a
/// deterministic, realistic list of desktop hardware devices per profile.
class MediaDevicesSpoof {
  static String generate(FingerprintConfig config) {
    final seed = config.canvasNoiseSalt.hashCode.abs();

    return '''
// ===== MEDIA DEVICES ENUMERATION SPOOFING =====
(() => {
  try {
    if (!navigator.mediaDevices) return;

    const profileSeed = $seed;

    // --- Deterministic ID generator ---
    // Generates a 64-char hex string from a numeric seed
    const generateDeviceId = (baseSeed) => {
      let state = baseSeed;
      let hex = '';
      for (let i = 0; i < 8; i++) {
        // Mulberry32 PRNG
        state += 0x6D2B79F5;
        let z = state;
        z = Math.imul(z ^ z >>> 15, z | 1);
        z ^= z + Math.imul(z ^ z >>> 7, z | 61);
        z ^= z >>> 14;
        const val = (z >>> 0);
        hex += val.toString(16).padStart(8, '0');
      }
      return hex;
    };

    // --- Curated desktop device name pools ---
    const videoInputs = [
      'Logitech HD Webcam C270',
      'Microsoft LifeCam HD-3000',
      'Logitech C920 Pro HD Webcam',
      'HP Webcam HD 4310',
      'Razer Kiyo',
      'AVerMedia Live Streamer CAM 313',
    ];

    const audioInputs = [
      'Default - Microphone (Realtek High Definition Audio)',
      'Headset Microphone (Razer Kraken)',
      'Microphone (USB Audio Device)',
      'Microphone (Blue Snowball)',
      'Default - Microphone (High Definition Audio Device)',
      'Integrated Microphone (Conexant HD Audio)',
    ];

    const audioOutputs = [
      'Default - Speakers (Realtek High Definition Audio)',
      'Headphones (Razer Kraken)',
      'Speakers (USB Audio Device)',
      'HDMI Audio Output (Intel Display Audio)',
      'Default - Speakers (High Definition Audio Device)',
      'Speakers (Conexant HD Audio)',
    ];

    // Deterministic selection from pools based on profile seed
    const pickFrom = (arr, seed) => arr[Math.abs(seed) % arr.length];

    const videoLabel = pickFrom(videoInputs, profileSeed);
    const audioInLabel = pickFrom(audioInputs, profileSeed + 1);
    const audioOutLabel = pickFrom(audioOutputs, profileSeed + 2);

    const camDeviceId   = generateDeviceId(profileSeed);
    const camGroupId    = generateDeviceId(profileSeed + 10);
    const micDeviceId   = generateDeviceId(profileSeed + 20);
    const micGroupId    = generateDeviceId(profileSeed + 30);
    const spkDeviceId   = generateDeviceId(profileSeed + 40);
    const spkGroupId    = generateDeviceId(profileSeed + 50);

    // Build spoofed MediaDeviceInfo-compatible objects
    const makeDeviceInfo = (kind, label, deviceId, groupId) => ({
      kind,
      label,
      deviceId,
      groupId,
      toJSON() {
        return { kind: this.kind, label: this.label, deviceId: this.deviceId, groupId: this.groupId };
      }
    });

    const spoofedDevices = [
      makeDeviceInfo('videoinput',  videoLabel,   camDeviceId, camGroupId),
      makeDeviceInfo('audioinput',  audioInLabel, micDeviceId, micGroupId),
      makeDeviceInfo('audiooutput', audioOutLabel, spkDeviceId, spkGroupId),
    ];

    // --- Override enumerateDevices ---
    const originalEnumerateDevices = navigator.mediaDevices.enumerateDevices.bind(navigator.mediaDevices);

    const spoofedEnumerateDevices = function() {
      return Promise.resolve(spoofedDevices);
    };

    window.__pbrowser_cloak(spoofedEnumerateDevices, 'function enumerateDevices() { [native code] }');

    try {
      Object.defineProperty(navigator.mediaDevices, 'enumerateDevices', {
        value: spoofedEnumerateDevices,
        writable: false,
        enumerable: true,
        configurable: true
      });
    } catch(e) {
      navigator.mediaDevices.enumerateDevices = spoofedEnumerateDevices;
    }

  } catch(e) {}
})();
''';
  }
}
