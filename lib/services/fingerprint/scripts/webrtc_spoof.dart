import 'package:pbrowser/models/fingerprint_config.dart';

/// JavaScript code generator for WebRTC leak prevention
class WebRTCSpoof {
  static String generate(FingerprintConfig config) {
    if (!config.webrtcEnabled) {
      // Completely disable WebRTC
      return '''
        if (typeof window.RTCPeerConnection !== 'undefined') {
          window.RTCPeerConnection = function() {
             throw new Error("WebRTC is disabled by strict security policy.");
          };
        }
        if (typeof window.webkitRTCPeerConnection !== 'undefined') {
          window.webkitRTCPeerConnection = window.RTCPeerConnection;
        }
      ''';
    } else {
      // Allow WebRTC but prevent IP leaks by filtering ICE candidates
      return '''
        const OriginalRTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection;
        if (OriginalRTCPeerConnection) {
          class ProxyPeerConnection extends OriginalRTCPeerConnection {
            constructor(config) {
              // Force ICE transport policy to 'relay' to prevent UDP leaks.
              config = config || {};
              config.iceTransportPolicy = 'relay';
              super(config);
              
              const originalAddIceCandidate = this.addIceCandidate;
              this.addIceCandidate = function(candidate, success, failure) {
                if (candidate && candidate.candidate) {
                  const str = candidate.candidate.toLowerCase();
                  if (str.includes('udp') && !str.includes('relay')) {
                    // Block non-proxied UDP candidates (Kill-switch)
                    if (success) success();
                    return Promise.resolve();
                  }
                  if (str.includes('tcp') && str.includes('host')) {
                    // Sometimes TCP host candidates surface internal IPs
                    if (success) success();
                    return Promise.resolve();
                  }
                }
                return originalAddIceCandidate.apply(this, arguments);
              };
            }
          }
          
          Object.defineProperty(window, 'RTCPeerConnection', {
            value: ProxyPeerConnection,
            writable: false,
            configurable: false
          });
          if (window.webkitRTCPeerConnection) {
            Object.defineProperty(window, 'webkitRTCPeerConnection', {
              value: ProxyPeerConnection,
              writable: false,
              configurable: false
            });
          }
        }
      ''';
    }
  }
}
