import 'package:SecTunnel/models/fingerprint_config.dart';

class WebglSpoof {
  static String generate(FingerprintConfig config) {
    return '''
      // 4. WEBGL IMPERFECTION
      (function() {
        const originalGetParameter = WebGLRenderingContext.prototype.getParameter;
        const originalGetShaderPrecisionFormat = WebGLRenderingContext.prototype.getShaderPrecisionFormat;

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

        EmulationEngine.patchMethod(WebGLRenderingContext.prototype, 'getParameter', function(parameter) {
          const result = originalGetParameter.call(this, parameter);
          return applyParameterJitter(result, parameter);
        });

        EmulationEngine.patchMethod(WebGLRenderingContext.prototype, 'getShaderPrecisionFormat', function(shaderType, precisionType) {
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
        });
      })();
''';
  }
}
