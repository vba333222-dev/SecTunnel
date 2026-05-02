class StatisticalAnomalyTest {
  static String getJS() {
    return '''
      try {
        // Calculate a basic anomaly score based on exposed features
        let anomalyScore = 0;
        
        const isMac = navigator.platform.toLowerCase().includes('mac');
        const isIOS = /iPhone|iPad|iPod/.test(navigator.platform);
        const isAndroid = /Android/.test(navigator.userAgent);
        
        if (isMac && navigator.userAgent.includes('Windows')) {
          anomalyScore += 50;
        }
        
        if (isIOS && !navigator.userAgent.includes('Safari')) {
          // All iOS browsers use WebKit, but UA should reflect it
          if (!navigator.userAgent.includes('WebKit')) anomalyScore += 40;
        }
        
        if (navigator.hardwareConcurrency === 1) {
          anomalyScore += 20; // Extremely rare in modern web
        }
        
        if (anomalyScore > 30) {
          report('Statistical Anomaly', false, `High anomaly score detected (\${anomalyScore})`, 'realism', Math.min(anomalyScore, 50));
        } else {
          report('Statistical Anomaly', true, 'No significant statistical anomalies detected', 'realism');
        }
      } catch(e) {
        report('Statistical Anomaly', false, `Error: \${e.message}`, 'realism', 10);
      }
    ''';
  }
}
