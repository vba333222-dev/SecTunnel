import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for WebRTC leak prevention
class WebRTCSpoof {
  static String generate(FingerprintConfig config) {
    if (!config.webrtcEnabled) {
      // Completely disable WebRTC
      return '''
// ===== WEBRTC DISABLED =====
(() => {
  try {
    // Use Object.defineProperty — `delete` silently fails on non-configurable globals
    const _undef = (obj, prop) => {
      try {
        Object.defineProperty(obj, prop, {
          value: undefined, writable: false, enumerable: false, configurable: false
        });
      } catch(e) {}
    };
    _undef(window, 'RTCPeerConnection');
    _undef(window, 'RTCSessionDescription');
    _undef(window, 'RTCIceCandidate');
    _undef(window, 'RTCDataChannel');
    _undef(window, 'RTCDTMFSender');
    _undef(window, 'webkitRTCPeerConnection');
    _undef(window, 'webkitRTCSessionDescription');
    _undef(window, 'webkitRTCIceCandidate');
    _undef(window, 'mozRTCPeerConnection');
    _undef(window, 'mozRTCSessionDescription');
    _undef(window, 'mozRTCIceCandidate');

    // Disable getUserMedia via Object.defineProperty on Navigator.prototype
    ['getUserMedia', 'webkitGetUserMedia', 'mozGetUserMedia'].forEach(fn => {
      try { _undef(Navigator.prototype, fn); } catch(e) {}
    });
    if (navigator.mediaDevices) {
      try { _undef(navigator.mediaDevices, 'getUserMedia'); } catch(e) {}
    }
  } catch(e) {}
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
  
  // Copy prototype chain and cloak constructor
  ProxiedRTCPeerConnection.prototype = OriginalRTCPeerConnection.prototype;
  Object.setPrototypeOf(ProxiedRTCPeerConnection, OriginalRTCPeerConnection);
  window.__pbrowser_cloak(ProxiedRTCPeerConnection, 'function RTCPeerConnection() { [native code] }');

  // Replace global RTCPeerConnection
  window.RTCPeerConnection = ProxiedRTCPeerConnection;
  if (window.webkitRTCPeerConnection) window.webkitRTCPeerConnection = ProxiedRTCPeerConnection;
  if (window.mozRTCPeerConnection)    window.mozRTCPeerConnection    = ProxiedRTCPeerConnection;
})();
''';
    }
  }
}
