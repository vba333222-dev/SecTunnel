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

      // --- High-End Desktop GPU Limits Dictionary ---
      const desktopGPULimits = {
        3379: 16384, // MAX_TEXTURE_SIZE (0x0D33)
        3386: new Int32Array([32768, 32768]), // MAX_VIEWPORT_DIMS (0x0D30)
        34076: 16384, // MAX_CUBE_MAP_TEXTURE_SIZE (0x851C)
        34024: 16384, // MAX_RENDERBUFFER_SIZE (0x0D3A)
        36348: 30, // MAX_VARYING_VECTORS (0x8DFC)
        34921: 16, // MAX_VERTEX_ATTRIBS (0x8869)
        35660: 32, // MAX_VERTEX_TEXTURE_IMAGE_UNITS (0x8B4C)
        36347: 4096, // MAX_VERTEX_UNIFORM_VECTORS (0x8DFB)
        33901: new Float32Array([1, 1]), // ALIASED_LINE_WIDTH_RANGE (0x846D)
        33902: new Float32Array([1, 1024]), // ALIASED_POINT_SIZE_RANGE (0x846E)
        36349: 4096, // MAX_FRAGMENT_UNIFORM_VECTORS (0x8DFD)
        34930: 32, // MAX_TEXTURE_IMAGE_UNITS (0x8872)
        36345: 32, // MAX_COMBINED_TEXTURE_IMAGE_UNITS (0x8DF9)
        
        // WebGL 2 specific limits
        32883: 2048, // MAX_3D_TEXTURE_SIZE (0x8073)
        35071: 2048, // MAX_ARRAY_TEXTURE_LAYERS (0x88FF)
        36063: 8, // MAX_COLOR_ATTACHMENTS (0x8CDF)
        34852: 8, // MAX_DRAW_BUFFERS (0x8824)
        35661: 32, // MAX_FRAGMENT_INPUT_COMPONENTS (0x8B4D, WebGL2)
        35659: 32, // MAX_VERTEX_OUTPUT_COMPONENTS (0x8B4B, WebGL2)
        34045: 16, // MAX_PROGRAM_TEXEL_OFFSET (0x84FD)
        34044: -8, // MIN_PROGRAM_TEXEL_OFFSET (0x84FC)
        
        // Identity info
        37445: '$vendor',   // UNMASKED_VENDOR_WEBGL
        37446: '$renderer', // UNMASKED_RENDERER_WEBGL
        7938:  'WebGL 1.0 (OpenGL ES 2.0 Chromium)', // VERSION (0x1F02)
        7936:  '$vendor',  // VENDOR (0x1F00)
        7937:  'WebKit', // RENDERER (0x1F01)
      };

      // --- getParameter spoof (Vendor / Renderer + key hardware params) ---
      const originalGetParameter = ctx.getParameter;
      const spoofedGetParameter = function(parameter) {
        if (parameter in desktopGPULimits) {
            return desktopGPULimits[parameter];
        }
        return originalGetParameter.apply(this, arguments);
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
