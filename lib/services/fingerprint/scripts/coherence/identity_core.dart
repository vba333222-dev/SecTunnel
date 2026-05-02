class IdentityCore {
  static String getJS() {
    return '''
      window.IdentityCore = (function() {
        const baseSeed = window.FINGERPRINT_SESSION_SEED || 12345;
        
        // Define the central personality
        const hardwareConcurrency = navigator.hardwareConcurrency || 4;
        const deviceMemory = navigator.deviceMemory || 4;
        const platform = navigator.platform.toLowerCase();
        const userAgent = navigator.userAgent.toLowerCase();
        
        const isMobile = /android|webos|iphone|ipad|ipod|blackberry|windows phone/.test(userAgent);
        const deviceClass = isMobile ? 'mobile' : 'desktop';
        
        // Centralize Tiering
        let cpuTier = 'mid';
        if (hardwareConcurrency <= 2 || deviceMemory <= 2) cpuTier = 'low';
        if (hardwareConcurrency >= 8 && deviceMemory >= 8) cpuTier = 'high';
        
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
        
        // Identity Persona
        const persona = {
          baseSeed: baseSeed,
          deviceClass: deviceClass,
          cpuTier: cpuTier,
          gpuTier: gpuTier,
          memoryTier: deviceMemory >= 8 ? 'high' : (deviceMemory <= 2 ? 'low' : 'mid'),
          platform: platform
        };

        if (window.console && window.console.debug) {
           // console.debug("[COHERENCE] Identity core initialized");
        }

        return {
          getPersona: function() { return persona; },
          getSeed: function() { return baseSeed; }
        };
      })();
    ''';
  }
}
