class WebGLSpoofV2 {
  static String getJS() {
    return '''
      (function() {
        if (!window.ImperfectionEngineV2 || !window.DeviceContext) return;
        
        const eng = window.ImperfectionEngineV2;
        const baseSeed = window.FINGERPRINT_SESSION_SEED || 12345;
        const renderSeed = eng.deriveSeed(baseSeed, window.DeviceContext.gpuTier);
        
        const originalGetParameter = WebGLRenderingContext.prototype.getParameter;
        
        const newGetParameter = function(parameter) {
          const result = originalGetParameter.call(this, parameter);
          
          if (typeof result === 'number') {
            const t = performance.now();
            const noise = eng.irregularNoise(parameter, renderSeed);
            const spike = eng.microSpike(t, renderSeed);
            
            // Floating point parameters get tiny non-linear drift
            if (result % 1 !== 0) {
               return result + (noise * 0.0001) + (spike * 0.001);
            }
          }
          
          return result;
        };
        
        WebGLRenderingContext.prototype.getParameter = newGetParameter;
        if (window.WebGL2RenderingContext) {
          WebGL2RenderingContext.prototype.getParameter = newGetParameter;
        }
        
        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newGetParameter, originalGetParameter);
        }
      })();
    ''';
  }
}
