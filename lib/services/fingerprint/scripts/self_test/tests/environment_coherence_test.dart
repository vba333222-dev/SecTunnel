class EnvironmentCoherenceTest {
  static String getJS() {
    return '''
      try {
        const platform = navigator.platform.toLowerCase();
        const touchPoints = navigator.maxTouchPoints;
        const memory = navigator.deviceMemory;
        const cores = navigator.hardwareConcurrency;
        
        // Platform ↔ TouchPoints Coherence
        if (platform.includes('win') && !platform.includes('phone')) {
           // Windows can have touch, but checking desktop mac vs touch
           if (platform.includes('mac') && touchPoints > 0) {
             report('Environment Coherence', false, 'Mac desktop with maxTouchPoints > 0 is anomalous', 'realism', 20);
           }
        }
        
        // Cores ↔ Memory Coherence
        if (cores > 16 && memory < 4) {
          report('Environment Coherence', false, 'High cores (>16) with very low memory (<4GB) is anomalous', 'realism', 30);
        } else {
          report('Environment Coherence', true, 'Hardware telemetry is coherent', 'realism');
        }
        
        // Timezone ↔ Locale Coherence
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
        const lang = navigator.language;
        // Simple heuristic check: if lang is ja-JP but timezone is Europe/Paris
        if (lang === 'ja-JP' && tz.includes('Europe')) {
          report('Environment Coherence', false, 'Timezone and language mismatch (ja-JP / Europe)', 'realism', 15);
        } else {
          report('Environment Coherence', true, 'Timezone and locale are acceptable', 'realism');
        }
        
      } catch(e) {
        report('Environment Coherence', false, `Error: \${e.message}`, 'realism', 10);
      }
    ''';
  }
}
