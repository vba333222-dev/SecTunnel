import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for WebGL fingerprint spoofing.
/// Spoofs Vendor, Renderer AND getSupportedExtensions/getExtension
/// to eliminate mobile GPU (Adreno/Mali) fingerprint signatures.
class WebGLSpoof {
  static String generate(FingerprintConfig config) {
    final vendor = _escapeJs(config.webglConfig.vendor);
    final renderer = _escapeJs(config.webglConfig.renderer);

    return '''
// ===== WEBGL DEEP SPOOFING (Vendor + Renderer + Extensions) =====
(() => {
  try {

    // ======================================================
    // SECTION 1: Extension Filter Lists
    // ======================================================

    // Mobile-exclusive extensions (OpenGL ES / Adreno / Mali / ASTC) to REMOVE
    const MOBILE_EXTENSION_BLOCKLIST = new Set([
      'WEBGL_compressed_texture_astc',
      'WEBGL_compressed_texture_etc',
      'WEBGL_compressed_texture_etc1',
      'WEBGL_compressed_texture_pvrtc',
      'WEBKIT_WEBGL_compressed_texture_pvrtc',
      'OES_texture_float_linear',          // Variable; present on desktop too but safely removed
      'EXT_texture_norm16',
      'WEBGL_provoking_vertex',
    ]);

    // Desktop-grade extensions to ADD (Standard DirectX / S3TC pipeline)
    const DESKTOP_EXTENSION_WHITELIST = [
      'WEBGL_compressed_texture_s3tc',
      'WEBGL_compressed_texture_s3tc_srgb',
      'EXT_texture_compression_bptc',
      'WEBGL_compressed_texture_rgtc',
    ];

    // ======================================================
    // SECTION 2: Helper to patch a single WebGL context prototype
    // ======================================================
    const patchWebGLContext = (ctx) => {
      if (!ctx) return;

      // --- getParameter spoof (Vendor / Renderer + key hardware params) ---
      const originalGetParameter = ctx.getParameter;
      const spoofedGetParameter = function(parameter) {
        switch(parameter) {
          // Identity
          case 37445: return '$vendor';   // UNMASKED_VENDOR_WEBGL
          case 37446: return '$renderer'; // UNMASKED_RENDERER_WEBGL
          // Desktop-grade texture limits (Intel iGPU baseline)
          case 0x0D33: return 16384;      // MAX_TEXTURE_SIZE (mobile: 4096–8192)
          case 0x851C: return 16384;      // MAX_CUBE_MAP_TEXTURE_SIZE
          case 0x8C29: return 4096;       // MAX_TEXTURE_IMAGE_UNITS (FS)
          case 0x84E8: return 16;         // MAX_TEXTURE_IMAGE_UNITS (total)
          case 0x0D3A: return 16384;      // MAX_RENDERBUFFER_SIZE
          case 0x8DF9: return 4096;       // MAX_COMBINED_TEXTURE_IMAGE_UNITS
          // Viewport / drawing limits
          case 0x0D30: return new Int32Array([16384, 16384]); // MAX_VIEWPORT_DIMS
          case 0x846D: return new Float32Array([1, 1]);       // ALIASED_LINE_WIDTH_RANGE
          case 0x846E: return new Float32Array([1, 1024]);    // ALIASED_POINT_SIZE_RANGE
          // Precision / version
          case 0x1F02: return 'WebGL 1.0 (OpenGL ES 2.0 Chromium)'; // VERSION
          case 0x1F00: return '$vendor';  // VENDOR
          case 0x1F01: return 'WebKit'; // RENDERER (non-unmasked, not real GPU)
          default:
            return originalGetParameter.apply(this, arguments);
        }
      };
      window.__pbrowser_cloak(spoofedGetParameter, 'function getParameter() { [native code] }');
      ctx.getParameter = spoofedGetParameter;

      // --- getSupportedExtensions spoof ---
      const originalGetSupportedExtensions = ctx.getSupportedExtensions;
      const spoofedGetSupportedExtensions = function() {
        const real = originalGetSupportedExtensions.apply(this, arguments) || [];
        // Filter out mobile extensions
        const filtered = real.filter(ext => !MOBILE_EXTENSION_BLOCKLIST.has(ext));
        // Add desktop extensions if not already present
        DESKTOP_EXTENSION_WHITELIST.forEach(ext => {
          if (!filtered.includes(ext)) filtered.push(ext);
        });
        return filtered;
      };
      window.__pbrowser_cloak(spoofedGetSupportedExtensions, 'function getSupportedExtensions() { [native code] }');
      ctx.getSupportedExtensions = spoofedGetSupportedExtensions;

      // --- getExtension spoof ---
      const originalGetExtension = ctx.getExtension;
      const spoofedGetExtension = function(name) {
        // Block mobile-specific extension requests
        if (MOBILE_EXTENSION_BLOCKLIST.has(name)) {
          return null;
        }
        // Return a stub object for desktop extensions that may not be natively present
        if (DESKTOP_EXTENSION_WHITELIST.includes(name)) {
          const real = originalGetExtension.apply(this, [name]);
          if (real) return real; // If the device supports it natively, use it
          // Return minimal stub object so code checking for truthiness works
          return {};
        }
        return originalGetExtension.apply(this, arguments);
      };
      window.__pbrowser_cloak(spoofedGetExtension, 'function getExtension() { [native code] }');
      ctx.getExtension = spoofedGetExtension;
    };

    // ======================================================
    // SECTION 3: Apply patches to WebGL1 and WebGL2
    // ======================================================
    patchWebGLContext(WebGLRenderingContext.prototype);

    if (typeof WebGL2RenderingContext !== 'undefined') {
      patchWebGLContext(WebGL2RenderingContext.prototype);
    }

  } catch(e) {}
})();
''';
  }

  static String _escapeJs(String str) {
    return str
        .replaceAll('\\\\', '\\\\\\\\')
        .replaceAll("'", "\\\\'")
        .replaceAll('"', '\\\\"')
        .replaceAll('\\n', '\\\\n')
        .replaceAll('\\r', '\\\\r');
  }
}
