class CanvasStabilityTest {
  static String getJS() {
    return '''
      try {
        function getCanvasHash() {
          const canvas = document.createElement('canvas');
          canvas.width = 200;
          canvas.height = 50;
          const ctx = canvas.getContext('2d');
          ctx.textBaseline = 'top';
          ctx.font = '14px Arial';
          ctx.fillStyle = '#f60';
          ctx.fillRect(125,1,62,20);
          ctx.fillStyle = '#069';
          ctx.fillText('Canvas Stability Test', 2, 15);
          ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
          ctx.fillText('Canvas Stability Test', 4, 17);
          return canvas.toDataURL();
        }
        
        const hashes = [];
        for(let i=0; i<5; i++) {
          hashes.push(getCanvasHash());
        }
        
        let stable = true;
        for(let i=1; i<hashes.length; i++) {
          if (hashes[i] !== hashes[0]) {
            stable = false;
            break;
          }
        }
        
        if (!stable) {
          report('Canvas Stability', false, 'Canvas output changes within same session', 'consistency', 40);
        } else {
          // Check if it's too perfect (no noise) by comparing to a known pure canvas if possible
          // Difficult to do without a reference, but we pass if stable per session.
          report('Canvas Stability', true, 'Canvas output is stable per session', 'consistency');
        }
      } catch(e) {
        report('Canvas Stability', false, `Error: \${e.message}`, 'consistency', 10);
      }
    ''';
  }
}
