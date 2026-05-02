class LeakDetectionTest {
  static String getJS() {
    return '''
      (async function() {
        try {
          // Check screen unpatched properties
          if (screen.width !== window.screen.width || screen.colorDepth !== window.screen.colorDepth) {
             report('Leak Detection', false, 'Screen object mismatch, properties leaking', 'stealth', 30);
          }
          
          // Check WebRTC
          if (window.RTCPeerConnection) {
            const pc = new RTCPeerConnection({ iceServers: [] });
            pc.createDataChannel("");
            const offer = await pc.createOffer();
            await pc.setLocalDescription(offer);
            
            const p = new Promise(resolve => {
              pc.onicecandidate = (ice) => {
                if (!ice || !ice.candidate) {
                  resolve(false); // No candidates leaked
                  return;
                }
                // Check if candidate contains local IP
                if (ice.candidate.candidate.match(/([0-9]{1,3}(\\.[0-9]{1,3}){3}|[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7})/)) {
                   if(ice.candidate.candidate.includes('.local')) {
                     // MDNS is fine
                   } else {
                     resolve(true); // IP leaked
                   }
                }
              };
              setTimeout(() => resolve(false), 1000);
            });
            
            const leaked = await p;
            if (leaked) {
              report('Leak Detection', false, 'WebRTC leaking local or real IP addresses', 'stealth', 60);
            } else {
              report('Leak Detection', true, 'WebRTC properly masked', 'stealth');
            }
          }
        } catch(e) {
          report('Leak Detection', false, `Error: \${e.message}`, 'stealth', 10);
        }
      })()
    ''';
  }
}
