class WebGLConsistencyTest {
  static String getJS() {
    return '''
      try {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (gl) {
          const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
          if (debugInfo) {
            const vendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL);
            const renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
            
            const platform = navigator.platform.toLowerCase();
            const isMac = platform.includes('mac');
            const isWin = platform.includes('win');
            
            // Simple heuristics
            if (isMac && renderer.toLowerCase().includes('adreno')) {
              report('WebGL Consistency', false, 'Adreno GPU detected on Mac platform', 'realism', 40);
            } else if (isWin && renderer.toLowerCase().includes('apple')) {
              report('WebGL Consistency', false, 'Apple GPU detected on Windows platform', 'realism', 40);
            } else {
              report('WebGL Consistency', true, 'WebGL vendor/renderer consistent with platform', 'realism');
            }
          }
        }
      } catch(e) {
        report('WebGL Consistency', false, `Error: \${e.message}`, 'realism', 10);
      }
    ''';
  }
}
