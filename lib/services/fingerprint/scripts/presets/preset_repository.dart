import 'device_preset.dart';
import 'behavior_profile.dart';

class PresetRepository {
  static final List<DevicePreset> presets = [
    // =========================================================
    // --- FLAGSHIP APPLE (iOS 18 / 17) ---
    // =========================================================
    DevicePreset(
      id: 'iphone_16_pro_max', name: 'iPhone 16 Pro Max', category: 'mobile',
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1',
      platform: 'iPhone', vendor: 'Apple Computer, Inc.', 
      hardwareConcurrency: 6, deviceMemory: 8, devicePixelRatio: 3.0,
      screenWidth: 440, screenHeight: 956, viewportWidth: 440, viewportHeight: 830,
      gpuVendor: 'Apple Inc.', gpuRenderer: 'Apple GPU', webglVersion: 'WebGL 2.0', maxTouchPoints: 5,
      timezone: 'America/New_York', locale: 'en-US', fonts: ['San Francisco', 'Helvetica Neue', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/mp4; codecs="hev1"'],
      behaviorProfile: BehaviorProfile.getProfile('low'), networkProfile: {'type': '5G', 'latency': 22}, weight: 12,
    ),
    DevicePreset(
      id: 'iphone_15_pro_max', name: 'iPhone 15 Pro Max', category: 'mobile',
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
      platform: 'iPhone', vendor: 'Apple Computer, Inc.', 
      hardwareConcurrency: 6, deviceMemory: 8, devicePixelRatio: 3.0,
      screenWidth: 430, screenHeight: 932, viewportWidth: 430, viewportHeight: 820,
      gpuVendor: 'Apple Inc.', gpuRenderer: 'Apple GPU', webglVersion: 'WebGL 2.0', maxTouchPoints: 5,
      timezone: 'America/Los_Angeles', locale: 'en-US', fonts: ['San Francisco', 'Helvetica Neue', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/mp4; codecs="hev1"'],
      behaviorProfile: BehaviorProfile.getProfile('low'), networkProfile: {'type': '5G', 'latency': 30}, weight: 15,
    ),
    DevicePreset(
      id: 'ipad_pro_m4', name: 'iPad Pro 13" (M4)', category: 'mobile',
      userAgent: 'Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      platform: 'iPad', vendor: 'Apple Computer, Inc.', 
      hardwareConcurrency: 10, deviceMemory: 8, devicePixelRatio: 2.0,
      screenWidth: 1024, screenHeight: 1366, viewportWidth: 1024, viewportHeight: 1260,
      gpuVendor: 'Apple Inc.', gpuRenderer: 'Apple M4 GPU', webglVersion: 'WebGL 2.0', maxTouchPoints: 5,
      timezone: 'Europe/London', locale: 'en-GB', fonts: ['San Francisco', 'Helvetica Neue', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/mp4; codecs="hev1"'],
      behaviorProfile: BehaviorProfile.getProfile('low'), networkProfile: {'type': 'WiFi', 'latency': 15}, weight: 8,
    ),

    // =========================================================
    // --- FLAGSHIP ANDROID (Android 14) ---
    // =========================================================
    DevicePreset(
      id: 'samsung_s24_ultra', name: 'Samsung Galaxy S24 Ultra', category: 'mobile',
      userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      platform: 'Linux aarch64', vendor: 'Google Inc.', 
      hardwareConcurrency: 8, deviceMemory: 12, devicePixelRatio: 3.0,
      screenWidth: 384, screenHeight: 832, viewportWidth: 384, viewportHeight: 720,
      gpuVendor: 'Qualcomm', gpuRenderer: 'Adreno (TM) 750', webglVersion: 'WebGL 2.0', maxTouchPoints: 10,
      timezone: 'Asia/Jakarta', locale: 'id-ID', fonts: ['Roboto', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('low'), networkProfile: {'type': '5G', 'latency': 40}, weight: 20,
    ),
    DevicePreset(
      id: 'google_pixel_8_pro', name: 'Google Pixel 8 Pro', category: 'mobile',
      userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      platform: 'Linux aarch64', vendor: 'Google Inc.', 
      hardwareConcurrency: 9, deviceMemory: 12, devicePixelRatio: 3.0,
      screenWidth: 384, screenHeight: 855, viewportWidth: 384, viewportHeight: 740,
      gpuVendor: 'Google', gpuRenderer: 'Google Tensor G3', webglVersion: 'WebGL 2.0', maxTouchPoints: 10,
      timezone: 'America/Chicago', locale: 'en-US', fonts: ['Roboto', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('low'), networkProfile: {'type': '5G', 'latency': 35}, weight: 15,
    ),

    // =========================================================
    // --- PREMIUM LAPTOPS / DESKTOPS ---
    // =========================================================
    DevicePreset(
      id: 'macbook_pro_14_m3', name: 'MacBook Pro 14" (M3)', category: 'laptop',
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      platform: 'MacIntel', vendor: 'Google Inc.', 
      hardwareConcurrency: 8, deviceMemory: 8, devicePixelRatio: 2.0,
      screenWidth: 1512, screenHeight: 982, viewportWidth: 1512, viewportHeight: 880,
      gpuVendor: 'Apple Inc.', gpuRenderer: 'Apple M3 GPU', webglVersion: 'WebGL 2.0', maxTouchPoints: 0,
      timezone: 'America/Los_Angeles', locale: 'en-US', fonts: ['San Francisco', 'Helvetica Neue', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/mp4; codecs="hev1"'],
      behaviorProfile: BehaviorProfile.getProfile('low'), networkProfile: {'type': 'WiFi', 'latency': 10}, weight: 12,
    ),
    DevicePreset(
      id: 'windows_11_chrome', name: 'Windows 11 Desktop (Chrome)', category: 'desktop',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      platform: 'Win32', vendor: 'Google Inc.', 
      hardwareConcurrency: 16, deviceMemory: 16, devicePixelRatio: 1.0,
      screenWidth: 1920, screenHeight: 1080, viewportWidth: 1920, viewportHeight: 1040,
      gpuVendor: 'Google Inc. (NVIDIA)', gpuRenderer: 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3080 Direct3D11 vs_5_0 ps_5_0)', webglVersion: 'WebGL 2.0', maxTouchPoints: 0,
      timezone: 'America/New_York', locale: 'en-US', fonts: ['Arial', 'Segoe UI', 'Times New Roman'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('medium'), networkProfile: {'type': 'broadband', 'latency': 5}, weight: 10,
    ),
    DevicePreset(
      id: 'windows_rtx_4090_pc', name: 'Windows Gaming PC (RTX 4090)', category: 'desktop',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      platform: 'Win32', vendor: 'Google Inc.', 
      hardwareConcurrency: 24, deviceMemory: 64, devicePixelRatio: 1.0,
      screenWidth: 2560, screenHeight: 1440, viewportWidth: 2560, viewportHeight: 1320,
      gpuVendor: 'Google Inc. (NVIDIA)', gpuRenderer: 'ANGLE (NVIDIA, NVIDIA GeForce RTX 4090 Direct3D11 vs_5_0 ps_5_0)', webglVersion: 'WebGL 2.0', maxTouchPoints: 0,
      timezone: 'Europe/Berlin', locale: 'de-DE', fonts: ['Arial', 'Segoe UI', 'Times New Roman'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('medium'), networkProfile: {'type': 'broadband', 'latency': 5}, weight: 10,
    ),

    // =========================================================
    // --- LINUX ECOSYSTEM ---
    // =========================================================
    DevicePreset(
      id: 'ubuntu_desktop_workstation', name: 'Ubuntu Desktop Workstation', category: 'desktop',
      userAgent: 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0',
      platform: 'Linux x86_64', vendor: '', 
      hardwareConcurrency: 12, deviceMemory: 16, devicePixelRatio: 1.0,
      screenWidth: 1920, screenHeight: 1080, viewportWidth: 1920, viewportHeight: 970,
      gpuVendor: 'Intel Open Source Technology Center', gpuRenderer: 'Mesa Intel(R) UHD Graphics (CML GT2)', webglVersion: 'WebGL 2.0', maxTouchPoints: 0,
      timezone: 'Europe/London', locale: 'en-GB', fonts: ['Ubuntu', 'Liberation Sans', 'DejaVu Sans'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('medium'), networkProfile: {'type': 'broadband', 'latency': 8}, weight: 25,
    ),
    DevicePreset(
      id: 'steam_deck_linux', name: 'Steam Deck (SteamOS Linux)', category: 'laptop',
      userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      platform: 'Linux x86_64', vendor: 'Google Inc.', 
      hardwareConcurrency: 8, deviceMemory: 16, devicePixelRatio: 1.0,
      screenWidth: 1280, screenHeight: 800, viewportWidth: 1280, viewportHeight: 720,
      gpuVendor: 'AMD', gpuRenderer: 'AMD Custom GPU 0405 (vangogh)', webglVersion: 'WebGL 2.0', maxTouchPoints: 10,
      timezone: 'America/Chicago', locale: 'en-US', fonts: ['Ubuntu', 'Liberation Sans', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 0, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('medium'), networkProfile: {'type': 'WiFi', 'latency': 20}, weight: 15,
    ),

    // =========================================================
    // --- MID-RANGE (Reliability) ---
    // =========================================================
    DevicePreset(
      id: 'samsung_a54_5g', name: 'Samsung Galaxy A54 5G', category: 'mobile',
      userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-A546B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
      platform: 'Linux aarch64', vendor: 'Google Inc.', 
      hardwareConcurrency: 8, deviceMemory: 8, devicePixelRatio: 2.625,
      screenWidth: 412, screenHeight: 915, viewportWidth: 412, viewportHeight: 810,
      gpuVendor: 'ARM', gpuRenderer: 'Mali-G68', webglVersion: 'WebGL 2.0', maxTouchPoints: 10,
      timezone: 'Asia/Bangkok', locale: 'th-TH', fonts: ['Roboto', 'Arial'], 
      mediaDevices: {'audioInput': 1, 'videoInput': 1, 'audioOutput': 1}, 
      codecs: ['video/mp4; codecs="avc1.42E01E"', 'video/webm; codecs="vp9"'],
      behaviorProfile: BehaviorProfile.getProfile('medium'), networkProfile: {'type': '4G/5G', 'latency': 45}, weight: 50,
    ),
  ];
}
