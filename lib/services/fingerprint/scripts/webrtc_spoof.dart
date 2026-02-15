import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for WebRTC leak prevention
class WebRTCSpoof {
  static String generate(FingerprintConfig config) {
    if (!config.webrtcEnabled) {
      // Completely disable WebRTC
      return '''
// ===== WEBRTC DISABLED =====
(() => {
  // Remove all WebRTC functionality
  delete window.RTCPeerConnection;
  delete window.RTCSessionDescription;
  delete window.RTCIceCandidate;
  delete window.webkitRTCPeerConnection;
  delete window.webkitRTCSessionDescription;
  delete window.webkitRTCIceCandidate;
  delete window.mozRTCPeerConnection;
  delete window.mozRTCSessionDescription;
  delete window.mozRTCIceCandidate;
  
  // Disable getUserMedia
  if (navigator.getUserMedia) {
    navigator.getUserMedia = undefined;
  }
  
  if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia = undefined;
  }
  
  if (navigator.webkitGetUserMedia) {
    navigator.webkitGetUserMedia = undefined;
  }
  
  if (navigator.mozGetUserMedia) {
    navigator.mozGetUserMedia = undefined;
  }
})();
''';
    } else {
      // Allow WebRTC but prevent IP leaks by filtering ICE candidates
      return '''
// ===== WEBRTC IP LEAK PREVENTION =====
(() => {
  // Get original RTCPeerConnection
  const OriginalRTCPeerConnection = (
    window.RTCPeerConnection ||
    window.webkitRTCPeerConnection ||
    window.mozRTCPeerConnection
  );
  
  if (!OriginalRTCPeerConnection) return;
  
  // Override RTCPeerConnection
  const ProxiedRTCPeerConnection = function(...args) {
    const pc = new OriginalRTCPeerConnection(...args);
    
    // Store original createOffer and createAnswer
    const originalCreateOffer = pc.createOffer;
    const originalCreateAnswer = pc.createAnswer;
    
    // Override createOffer
    pc.createOffer = function(...args) {
      return originalCreateOffer.apply(this, args).then(sdp => {
        // Remove host candidates (local IPs)
        sdp.sdp = sdp.sdp.split('\\n').filter(line => {
          // Keep only relay and srflx candidates, remove host
          if (line.includes('a=candidate')) {
            return !line.includes(' typ host ');
          }
          return true;
        }).join('\\n');
        
        return sdp;
      });
    };
    
    // Override createAnswer
    pc.createAnswer = function(...args) {
      return originalCreateAnswer.apply(this, args).then(sdp => {
        sdp.sdp = sdp.sdp.split('\\n').filter(line => {
          if (line.includes('a=candidate')) {
            return !line.includes(' typ host ');
          }
          return true;
        }).join('\\n');
        
        return sdp;
      });
    };
    
    return pc;
  };
  
  // Copy static methods
  ProxiedRTCPeerConnection.prototype = OriginalRTCPeerConnection.prototype;
  
  // Replace global RTCPeerConnection
  window.RTCPeerConnection = ProxiedRTCPeerConnection;
  window.webkitRTCPeerConnection = ProxiedRTCPeerConnection;
  window.mozRTCPeerConnection = ProxiedRTCPeerConnection;
})();
''';
    }
  }
}
