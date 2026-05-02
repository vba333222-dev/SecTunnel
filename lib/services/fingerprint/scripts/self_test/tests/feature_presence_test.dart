class FeaturePresenceTest {
  static String getJS() {
    return '''
      try {
        const expectedNavProps = ['userAgent', 'platform', 'hardwareConcurrency', 'deviceMemory', 'languages', 'plugins', 'cookieEnabled'];
        let missing = [];
        for (const prop of expectedNavProps) {
          if (!(prop in navigator)) {
            missing.push(prop);
          }
        }
        
        if (missing.length > 0) {
          report('Feature Presence', false, `Missing expected navigator APIs: \${missing.join(', ')}`, 'stealth', 30);
        } else {
          report('Feature Presence', true, 'All expected navigator APIs present', 'stealth');
        }
        
        // Check for unrealistic APIs (e.g. webdriver should be false/undefined naturally)
        if (navigator.webdriver) {
          report('WebDriver Presence', false, 'navigator.webdriver is true, highly detectable', 'stealth', 80);
        } else {
          report('WebDriver Presence', true, 'WebDriver is properly hidden', 'stealth');
        }
      } catch(e) {
        report('Feature Presence', false, `Error: \${e.message}`, 'stealth', 10);
      }
    ''';
  }
}
