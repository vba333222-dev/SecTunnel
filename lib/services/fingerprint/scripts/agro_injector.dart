import 'package:sec_tunnel/models/fingerprint_config.dart';

/// Aggressive Fingerprint Hardening Script (Phase 29: Deep-Core Leakage Patch + Hijackers)
/// This script implements deep prototype-level cloaking for identity, GPU, WebRTC,
/// and adds advanced hijacking for Iframes and Web Workers to kill CreepJS bypasses.
class AgroInjector {
  static String generate(FingerprintConfig config) {
    final platform = config.platform;
    final vendor = config.vendor;
    final gpuVendor = config.webglConfig.vendor;
    final gpuRenderer = config.webglConfig.renderer;
    
    // Derived UA-CH brands based on Chrome version
    final chromeVersion = _extractChromeMajor(config.userAgent);
    
    return '''
// ===== KERNEL-LEVEL CLOAKING (PHASE 30: CREEPJS MASTER BYPASS) =====
(() => {
  try {
    const globalScope = (typeof window !== 'undefined' ? window : self);
    if (globalScope.__pbrowser_agro_injected) return;
    globalScope.__pbrowser_agro_injected = true;

    const cloak = globalScope.__pbrowser_cloak || (fn => fn);

    // 1. PROTOTYPE NUKING: NavigatorUAData
    (() => {
      const brands = [
        { brand: 'Not_A Brand', version: '8' },
        { brand: 'Chromium', version: '$chromeVersion' },
        { brand: 'Google Chrome', version: '$chromeVersion' }
      ];

      const NavigatorUADataProxy = cloak(function() {
        throw new TypeError("Illegal constructor");
      }, 'function NavigatorUAData() { [native code] }');

      const uaDataInstance = Object.create(NavigatorUADataProxy.prototype);

      Object.defineProperties(uaDataInstance, {
        brands: { get: cloak(() => brands, 'function get brands() { [native code] }'), enumerable: true, configurable: true },
        mobile: { get: cloak(() => false, 'function get mobile() { [native code] }'), enumerable: true, configurable: true },
        platform: { get: cloak(() => '${_normalizePlatform(platform)}', 'function get platform() { [native code] }'), enumerable: true, configurable: true },
        getHighEntropyValues: { 
          value: cloak(() => Promise.resolve({
            brands: brands,
            mobile: false,
            platform: '${_normalizePlatform(platform)}',
            architecture: 'x86',
            bitness: '64',
            model: '',
            platformVersion: '14.4.1',
            uaFullVersion: '$chromeVersion.0.0.0'
          }), 'function getHighEntropyValues() { [native code] }'), 
          enumerable: true, configurable: true, writable: true 
        },
        toJSON: { 
          value: cloak(() => ({ brands: brands, mobile: false, platform: '${_normalizePlatform(platform)}' }), 'function toJSON() { [native code] }'), 
          enumerable: true, configurable: true, writable: true 
        }
      });

      // Kernel-Level Override on Prototype
      Object.defineProperty(Navigator.prototype, 'userAgentData', {
        get: cloak(() => uaDataInstance, 'function get userAgentData() { [native code] }'),
        configurable: true, enumerable: true
      });
      
      // Fix platform/vendor consistency
      Object.defineProperty(Navigator.prototype, 'platform', {
        get: cloak(() => '$platform', 'function get platform() { [native code] }'),
        configurable: true, enumerable: true
      });
      Object.defineProperty(Navigator.prototype, 'vendor', {
        get: cloak(() => '$vendor', 'function get vendor() { [native code] }'),
        configurable: true, enumerable: true
      });
    })();

    // 2. PROTOTYPE NUKING: WebGL (Hard-coded to Apple GPU for Stealth)
    (() => {
      const patchWebGL = (proto) => {
        if (!proto || !proto.getParameter) return;
        const originalGetParam = proto.getParameter;
        
        Object.defineProperty(proto, 'getParameter', {
          value: cloak(function(param) {
            // UNMASKED_VENDOR_WEBGL (37445), UNMASKED_RENDERER_WEBGL (37446)
            if (param === 37445 || param === 0x1F00) return "Apple Inc.";
            if (param === 37446 || param === 0x1F01) return "Apple GPU";
            
            const result = originalGetParam.apply(this, arguments);
            if (typeof result === 'number' && !Number.isInteger(result)) {
              return result + (Math.random() - 0.5) * 1e-11;
            }
            return result;
          }, 'function getParameter() { [native code] }'),
          configurable: true, writable: true
        });
      };

      if (globalScope.WebGLRenderingContext) patchWebGL(WebGLRenderingContext.prototype);
      if (globalScope.WebGL2RenderingContext) patchWebGL(WebGL2RenderingContext.prototype);
    })();

    // 3. WEBRTC TOTAL REMOVAL (Local IP Leak Killer)
    (() => {
      try {
        delete globalScope.RTCPeerConnection;
        delete globalScope.mozRTCPeerConnection;
        delete globalScope.webkitRTCPeerConnection;
        delete globalScope.RTCSessionDescription;
        delete globalScope.RTCIceCandidate;
      } catch(e) {}
    })();

    // 4. PROTOTYPE NUKING: Battery Status
    (() => {
      if (typeof Navigator !== 'undefined' && Navigator.prototype.getBattery) {
        Object.defineProperty(Navigator.prototype, 'getBattery', {
          value: cloak(() => Promise.resolve({
            charging: true,
            chargingTime: 0,
            dischargingTime: Infinity,
            level: 1.0,
            onchargingchange: null,
            onchargingtimechange: null,
            ondischargingtimechange: null,
            onlevelchange: null
          }), 'function getBattery() { [native code] }'),
          configurable: true, writable: true
        });
      }
    })();

    // 5. BLOB WORKER HIJACKER (Kernel Hook on URL & Blob)
    (() => {
      const OriginalBlob = globalScope.Blob;
      const OriginalURL = globalScope.URL;
      const OriginalWorker = globalScope.Worker;

      const WORKER_SPOOF_HEADER = `
        (function(self) {
          try {
            if (self.__pbrowser_agro_injected) return;
            const _master = \${JSON.stringify(globalScope.__pbrowser_master_script)};
            if (_master) {
              eval('(' + _master + ')(self);');
            }
          } catch(e) {}
        })(self);
      `;

      // Hook Blob to inject header into JS blobs
      globalScope.Blob = cloak(function(parts, options) {
        if (options && (options.type === 'application/javascript' || options.type === 'text/javascript')) {
          parts.unshift(WORKER_SPOOF_HEADER + "\\n");
        }
        return new OriginalBlob(parts, options);
      }, 'function Blob() { [native code] }');
      globalScope.Blob.prototype = OriginalBlob.prototype;

      // Hook createObjectURL as requested
      const origCreateURL = OriginalURL.createObjectURL;
      globalScope.URL.createObjectURL = cloak(function(obj) {
        return origCreateURL.apply(this, arguments);
      }, 'function createObjectURL() { [native code] }');

      // Hook Worker to ensure blob propagation
      globalScope.Worker = cloak(function(scriptURL, options) {
        return new OriginalWorker(scriptURL, options);
      }, 'function Worker() { [native code] }');
      globalScope.Worker.prototype = OriginalWorker.prototype;
    })();

    // 6. IFRAME PENETRATION (Prototype Accessor Hook)
    (() => {
      if (typeof HTMLIFrameElement === 'undefined') return;
      
      const patchWindow = (win) => {
        try {
          if (!win || win.__pbrowser_agro_injected) return;
          const master = globalScope.__pbrowser_master_script;
          if (master) win.eval('(' + master + ')(window);');
        } catch(e) {}
      };

      const originalCW = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'contentWindow').get;
      Object.defineProperty(HTMLIFrameElement.prototype, 'contentWindow', {
        get: cloak(function() {
          const win = originalCW.apply(this);
          patchWindow(win);
          return win;
        }, 'function get contentWindow() { [native code] }'),
        configurable: true
      });

      const originalCD = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'contentDocument').get;
      Object.defineProperty(HTMLIFrameElement.prototype, 'contentDocument', {
        get: cloak(function() {
          const doc = originalCD.apply(this);
          if (doc) patchWindow(doc.defaultView);
          return doc;
        }, 'function get contentDocument() { [native code] }'),
        configurable: true
      });
    })();

  } catch(e) {
    console.error('AgroInjector Phase 30 Error:', e);
  }
})(typeof window !== 'undefined' ? window : self);
''';
  }

  static String _extractChromeMajor(String ua) {
    final regex = RegExp(r'Chrome/(\d+)');
    final match = regex.firstMatch(ua);
    return match?.group(1) ?? '125';
  }

  static String _normalizePlatform(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('win')) return 'Windows';
    if (p.contains('mac')) return 'macOS';
    if (p.contains('android')) return 'Android';
    if (p.contains('linux')) return 'Linux';
    return 'Windows';
  }
}
