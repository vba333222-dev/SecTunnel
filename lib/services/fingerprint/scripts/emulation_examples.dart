class EmulationExamples {
  static String get patchesJs => r'''
    // --- NAVIGATOR PATCH EXAMPLE ---
    EmulationEngine.patchGetter(Navigator.prototype, 'hardwareConcurrency', function() {
      return 8;
    });

    EmulationEngine.patchGetter(Navigator.prototype, 'userAgent', function() {
      return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    });

    // --- WEBGL PATCH EXAMPLE ---
    if (typeof WebGLRenderingContext !== 'undefined') {
      const originalGetParameter = WebGLRenderingContext.prototype.getParameter;
      EmulationEngine.patchMethod(WebGLRenderingContext.prototype, 'getParameter', function(parameter) {
        if (parameter === 37445) { // UNMASKED_VENDOR_WEBGL
          return "Intel Inc.";
        }
        if (parameter === 37446) { // UNMASKED_RENDERER_WEBGL
          return "Intel Iris OpenGL Engine";
        }
        return originalGetParameter.call(this, parameter);
      });
    }

    if (typeof WebGL2RenderingContext !== 'undefined') {
      const originalGetParameter2 = WebGL2RenderingContext.prototype.getParameter;
      EmulationEngine.patchMethod(WebGL2RenderingContext.prototype, 'getParameter', function(parameter) {
        if (parameter === 37445) {
          return "Intel Inc.";
        }
        if (parameter === 37446) {
          return "Intel Iris OpenGL Engine";
        }
        return originalGetParameter2.call(this, parameter);
      });
    }

    // --- SCREEN PATCH EXAMPLE ---
    EmulationEngine.patchGetter(Screen.prototype, 'width', function() {
      return 1920;
    });

    EmulationEngine.patchGetter(Screen.prototype, 'height', function() {
      return 1080;
    });

    EmulationEngine.patchGetter(Screen.prototype, 'colorDepth', function() {
      return 24;
    });
''';
}
