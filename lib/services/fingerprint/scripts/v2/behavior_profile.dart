class BehaviorProfile {
  static String getJS() {
    return '''
      window.BehaviorProfile = (function() {
        if (!window.DeviceContext || !window.ImperfectionEngineV2) return null;
        
        const ctx = window.DeviceContext;
        const baseSeed = window.FINGERPRINT_SESSION_SEED || 12345;
        
        // Derive specific behavior seed
        const behaviorSeed = window.ImperfectionEngineV2.deriveSeed(baseSeed, ctx.cpuTier + ctx.deviceClass);
        
        let baseLatency = 5;
        let jitterIntensity = 1.0;
        let scrollInertia = 0.9;
        let interactionSpeed = 1.0;
        
        if (ctx.deviceClass === 'mobile') {
          baseLatency += 10;
          scrollInertia = 0.95; // More inertia on mobile touch
          interactionSpeed = 0.8;
        }
        
        if (ctx.cpuTier === 'low') {
          baseLatency += 15;
          jitterIntensity = 2.5;
          interactionSpeed = 0.6;
        } else if (ctx.cpuTier === 'high') {
          baseLatency = Math.max(1, baseLatency - 2);
          jitterIntensity = 0.5;
          interactionSpeed = 1.2;
        }
        
        // Mix in deterministic noise based on seed
        const offset = window.ImperfectionEngineV2.irregularNoise(1, behaviorSeed);
        baseLatency += offset * 2;
        jitterIntensity *= (1 + offset * 0.1);

        if (window.console && window.console.debug) {
           // console.debug("[BEHAVIOR] Context-aware model active");
           // console.debug("[BEHAVIOR] Device profile applied: " + ctx.deviceClass + " / " + ctx.cpuTier);
        }

        return {
          baseLatency,
          jitterIntensity,
          scrollInertia,
          interactionSpeed,
          behaviorSeed
        };
      })();
    ''';
  }
}
