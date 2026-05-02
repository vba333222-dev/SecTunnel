class CrossContextTest {
  static String getJS() {
    return '''
      try {
        const iframe = document.createElement('iframe');
        iframe.style.display = 'none';
        document.body.appendChild(iframe);
        
        const frameNav = iframe.contentWindow.navigator;
        const mainNav = window.navigator;
        
        let match = true;
        const props = ['userAgent', 'platform', 'hardwareConcurrency', 'deviceMemory'];
        
        for (const p of props) {
          if (frameNav[p] !== mainNav[p]) {
            match = false;
            report('Cross-Context Consistency', false, `Mismatch in \${p} between main window and iframe`, 'consistency', 30);
            break;
          }
        }
        
        if (match) {
          report('Cross-Context Consistency', true, 'Iframe navigator matches main navigator', 'consistency');
        }
        
        document.body.removeChild(iframe);
      } catch (e) {
        report('Cross-Context Consistency', false, `Test failed to execute: \${e.message}`, 'consistency', 10);
      }
    ''';
  }
}
