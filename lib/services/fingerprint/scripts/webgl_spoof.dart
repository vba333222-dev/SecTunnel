import 'package:sec_tunnel/models/fingerprint_config.dart';

class WebglSpoof {
  static String generate(FingerprintConfig config) {
    // Escape vendor/renderer for JS string safety
    final vendor = config.webglConfig.vendor.replaceAll("'", "\\'");
    final renderer = config.webglConfig.renderer.replaceAll("'", "\\'");

    return '''
      // 4. WEBGL HARDENING
      (function() {
        const UNMASKED_VENDOR_WEBGL = 0x9245;
        const UNMASKED_RENDERER_WEBGL = 0x9246;
        
        const vendor = '$vendor';
        const renderer = '$renderer';

        function patchContext(proto) {
          if (!proto) return;
          
          const originalGetParameter = proto.getParameter;
          const originalGetShaderPrecisionFormat = proto.getShaderPrecisionFormat;

          function applyParameterJitter(result, parameter) {
            if (result instanceof Float32Array) {
              const spoofed = new Float32Array(result.length);
              for (let i = 0; i < result.length; i++) {
                spoofed[i] = _imperfectionMicroJitter(result[i], _webglSeed ^ parameter ^ i);
              }
              return spoofed;
            }
            return result;
          }

          const spoofedGetParameter = function(parameter) {
            if (parameter === UNMASKED_VENDOR_WEBGL) return vendor;
            if (parameter === UNMASKED_RENDERER_WEBGL) return renderer;
            
            const result = originalGetParameter.call(this, parameter);
            return applyParameterJitter(result, parameter);
          };
          
          self.__pbrowser_cloak(spoofedGetParameter, 'function getParameter() { [native code] }');
          proto.getParameter = spoofedGetParameter;

          const spoofedGetShaderPrecisionFormat = function(shaderType, precisionType) {
            const result = originalGetShaderPrecisionFormat.call(this, shaderType, precisionType);
            if (result) {
              const precisionVar = Math.round(_imperfectionMicroJitter(result.precision, _webglSeed ^ shaderType ^ precisionType) - result.precision);
              const rangeMinVar = Math.round(_imperfectionMicroJitter(result.rangeMin, _webglSeed ^ shaderType ^ precisionType ^ 1) - result.rangeMin);
              const rangeMaxVar = Math.round(_imperfectionMicroJitter(result.rangeMax, _webglSeed ^ shaderType ^ precisionType ^ 2) - result.rangeMax);
              
              const obj = Object.create(WebGLShaderPrecisionFormat.prototype);
              Object.defineProperty(obj, 'precision', { value: result.precision + (precisionVar ? 1 : 0), configurable: true, enumerable: true });
              Object.defineProperty(obj, 'rangeMin', { value: result.rangeMin + (rangeMinVar ? 1 : 0), configurable: true, enumerable: true });
              Object.defineProperty(obj, 'rangeMax', { value: result.rangeMax + (rangeMaxVar ? 1 : 0), configurable: true, enumerable: true });
              return obj;
            }
            return result;
          };

          self.__pbrowser_cloak(spoofedGetShaderPrecisionFormat, 'function getShaderPrecisionFormat() { [native code] }');
          proto.getShaderPrecisionFormat = spoofedGetShaderPrecisionFormat;
        }

        patchContext(WebGLRenderingContext.prototype);
        if (typeof WebGL2RenderingContext !== 'undefined') {
          patchContext(WebGL2RenderingContext.prototype);
        }
      })();
''';
  }
}
