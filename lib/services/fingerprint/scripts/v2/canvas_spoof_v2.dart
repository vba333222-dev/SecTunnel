class CanvasSpoofV2 {
  static String getJS() {
    return '''
      (function() {
        if (!window.ImperfectionEngineV2 || !window.DeviceContext) return;
        
        const eng = window.ImperfectionEngineV2;
        const baseSeed = window.FINGERPRINT_SESSION_SEED || 12345;
        const renderSeed = eng.deriveSeed(baseSeed, window.DeviceContext.gpuTier);
        
        const originalGetImageData = CanvasRenderingContext2D.prototype.getImageData;
        const originalToDataURL = HTMLCanvasElement.prototype.toDataURL;
        
        const applyNoise = (canvas, ctx) => {
          try {
            const width = canvas.width;
            const height = canvas.height;
            if (width === 0 || height === 0) return;
            
            const imageData = originalGetImageData.call(ctx, 0, 0, width, height);
            const data = imageData.data;
            
            const t = performance.now();
            const spike = eng.microSpike(t, renderSeed);
            
            for (let i = 0; i < data.length; i += 4) {
              const noise = eng.irregularNoise(i, renderSeed) * 2; // bounded drift
              const anomaly = spike > 0 && i % 17 === 0 ? spike * 10 : 0; // micro-anomaly injection
              
              data[i] = Math.max(0, Math.min(255, data[i] + noise + anomaly));
              data[i+1] = Math.max(0, Math.min(255, data[i+1] + noise - anomaly));
              data[i+2] = Math.max(0, Math.min(255, data[i+2] - noise + anomaly));
            }
            
            ctx.putImageData(imageData, 0, 0);
          } catch(e) {}
        };
        
        const newToDataURL = function(...args) {
          const ctx = this.getContext('2d');
          if (ctx) applyNoise(this, ctx);
          return originalToDataURL.apply(this, args);
        };
        
        const newGetImageData = function(...args) {
          applyNoise(this.canvas, this);
          return originalGetImageData.apply(this, args);
        };
        
        HTMLCanvasElement.prototype.toDataURL = newToDataURL;
        CanvasRenderingContext2D.prototype.getImageData = newGetImageData;
        
        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newToDataURL, originalToDataURL);
          window.FunctionCloaker.cloak(newGetImageData, originalGetImageData);
        }
      })();
    ''';
  }
}
