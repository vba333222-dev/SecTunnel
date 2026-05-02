class DeviceContext {
  static String getJS() {
    return '''
      window.DeviceContext = (function() {
        const platform = navigator.platform.toLowerCase();
        const userAgent = navigator.userAgent.toLowerCase();
        const cores = navigator.hardwareConcurrency || 4;
        const memory = navigator.deviceMemory || 4;
        
        const isMobile = /android|webos|iphone|ipad|ipod|blackberry|windows phone/.test(userAgent);
        const deviceClass = isMobile ? 'mobile' : 'desktop';
        
        let cpuTier = 'mid';
        if (cores <= 2 || memory <= 2) cpuTier = 'low';
        if (cores >= 8 && memory >= 8) cpuTier = 'high';
        
        // Infer GPU tier based on standard WebGL info
        let gpuTier = 'mid';
        try {
          const canvas = document.createElement('canvas');
          const gl = canvas.getContext('webgl');
          if (gl) {
            const ext = gl.getExtension('WEBGL_debug_renderer_info');
            const renderer = ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL).toLowerCase() : '';
            if (renderer.includes('rtx') || renderer.includes('apple m')) gpuTier = 'high';
            if (renderer.includes('intel hd') || renderer.includes('adreno 3') || renderer.includes('mali-4')) gpuTier = 'low';
          }
        } catch(e) {}

        return {
          deviceClass,
          cpuTier,
          gpuTier,
          memoryTier: memory >= 8 ? 'high' : (memory <= 2 ? 'low' : 'mid')
        };
      })();
    ''';
  }
}
