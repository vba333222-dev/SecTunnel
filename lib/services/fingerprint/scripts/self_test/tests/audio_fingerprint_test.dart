class AudioFingerprintTest {
  static String getJS() {
    return '''
      (async function() {
        try {
          const ctx = new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 44100, 44100);
          const osc = ctx.createOscillator();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(10000, ctx.currentTime);
          
          const compressor = ctx.createDynamicsCompressor();
          [
            ['threshold', -50],
            ['knee', 40],
            ['ratio', 12],
            ['reduction', -20],
            ['attack', 0],
            ['release', .25]
          ].forEach(function(item) {
            if (compressor[item[0]] !== undefined && typeof compressor[item[0]].setValueAtTime === 'function') {
              compressor[item[0]].setValueAtTime(item[1], ctx.currentTime);
            }
          });
          
          osc.connect(compressor);
          compressor.connect(ctx.destination);
          osc.start(0);
          
          const buffer = await new Promise(resolve => {
            ctx.oncomplete = (e) => resolve(e.renderedBuffer);
            ctx.startRendering();
          });
          
          const data = buffer.getChannelData(0);
          
          // Check for stability
          if (data[4500] === undefined) {
             report('Audio Fingerprint', false, 'Audio buffer generation failed', 'consistency', 20);
          } else {
             // We can check if noise is added by verifying if values are strictly predictable
             report('Audio Fingerprint', true, 'Audio oscillator successfully rendered without crashing', 'consistency');
          }
        } catch(e) {
          report('Audio Fingerprint', false, `Error: \${e.message}`, 'consistency', 10);
        }
      })()
    ''';
  }
}
