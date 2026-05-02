class TimingAnalysisTest {
  static String getJS() {
    return '''
      (async function() {
        const samples = [];
        for(let i=0; i<500; i++) {
          samples.push(performance.now());
        }
        
        const diffs = [];
        for(let i=1; i<samples.length; i++) {
          diffs.push(samples[i] - samples[i-1]);
        }
        
        // Check variance
        let hasVariance = false;
        const base = diffs[0];
        for(let i=1; i<diffs.length; i++) {
          if (diffs[i] !== base && Math.abs(diffs[i] - base) > 0.0001) {
            hasVariance = true;
            break;
          }
        }
        
        if (!hasVariance) {
          // It's too perfect, unrealistic
          report('Timing Analysis', false, 'performance.now() is uniformly perfect, unrealistic stability', 'realism', 20);
        } else {
          report('Timing Analysis', true, 'Natural variance detected in timing APIs', 'realism');
        }
        
        // Test setTimeout delay pattern
        return new Promise((resolve) => {
          const t0 = performance.now();
          setTimeout(() => {
            const t1 = performance.now();
            const delay = t1 - t0;
            if (delay < 0) {
              report('Timeout Analysis', false, 'Negative timeout delay detected', 'stealth', 50);
            } else if (Math.abs(delay - 0) < 0.1) {
               // 0ms timeout should still take ~1-4ms
              report('Timeout Analysis', false, 'Timeout executed too fast (unrealistic microtask handling)', 'realism', 20);
            } else {
              report('Timeout Analysis', true, 'Realistic timeout delay', 'realism');
            }
            resolve();
          }, 0);
        });
      })()
    ''';
  }
}
