import 'package:sec_tunnel/models/fingerprint_config.dart';

class CanvasSpoof {
  static String generate(FingerprintConfig config) {
    return '''
      // 3. CANVAS IMPERFECTION
      (function() {
        const originalToDataURL = HTMLCanvasElement.prototype.toDataURL;
        const originalGetImageData = CanvasRenderingContext2D.prototype.getImageData;

        function applyCanvasImperfection(canvas, context) {
          try {
            const width = canvas.width;
            const height = canvas.height;
            if (width === 0 || height === 0) return;

            const imageData = originalGetImageData.call(context, 0, 0, width, height);
            const data = imageData.data;
            
            // Deterministic sub-seed based on canvas dimensions and content sample
            let contentSample = data[0] + data[Math.floor(data.length / 2)] + data[data.length - 1];
            let subSeed = _xorshift32(_canvasSeed ^ width ^ height ^ contentSample);

            // Add pixel-level micro variation to a few pixels (R, G, B channels)
            for (let i = 0; i < data.length; i += 4) {
              if ((i / 4) % 17 === 0) { 
                let s = _xorshift32(subSeed ^ i);
                let variation = Math.round((s / 4294967296) * 4 - 2); // -2 to 2
                data[i] = Math.max(0, Math.min(255, data[i] + variation));
                data[i+1] = Math.max(0, Math.min(255, data[i+1] + variation));
                data[i+2] = Math.max(0, Math.min(255, data[i+2] + variation));
              }
            }
            context.putImageData(imageData, 0, 0);
          } catch(e) {}
        }

        EmulationEngine.patchMethod(HTMLCanvasElement.prototype, 'toDataURL', function(...args) {
          const context = this.getContext('2d');
          if (context) applyCanvasImperfection(this, context);
          return originalToDataURL.apply(this, args);
        });

        EmulationEngine.patchMethod(CanvasRenderingContext2D.prototype, 'getImageData', function(...args) {
          applyCanvasImperfection(this.canvas, this);
          return originalGetImageData.apply(this, args);
        });
      })();
''';
  }
}
