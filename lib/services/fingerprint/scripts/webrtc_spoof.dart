import 'package:sec_tunnel/models/fingerprint_config.dart';

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
      // Allow WebRTC but prevent IP leaks by filtering ICE candidates and sanitizing SDP
      return '''
        (function() {
          const OriginalRTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection;
          if (!OriginalRTCPeerConnection) return;

          function sanitizeSDP(sdp) {
            if (typeof sdp !== 'string') return sdp;
            // Remove candidate lines that often contain local IP addresses
            // Also mask m=video/audio IP addresses
            return sdp.replace(/a=candidate:.*?\\r\\n/g, '')
                      .replace(/\\bc=[^\\r\\n]+\\b/g, 'c=IN IP4 0.0.0.0');
          }

          class ProxyPeerConnection extends OriginalRTCPeerConnection {
            constructor(config) {
              // Force ICE transport policy to 'relay' to prevent UDP leaks.
              config = config || {};
              config.iceTransportPolicy = 'relay';
              config.iceServers = config.iceServers || [];
              
              super(config);
              
              const self = this;

              // 1. Sanitize Offers
              const originalCreateOffer = this.createOffer;
              this.createOffer = function() {
                return originalCreateOffer.apply(this, arguments).then(offer => {
                  if (offer && offer.sdp) {
                    offer.sdp = sanitizeSDP(offer.sdp);
                  }
                  return offer;
                });
              };
              window.__pbrowser_cloak(this.createOffer, 'function createOffer() { [native code] }');

              // 2. Sanitize Answers
              const originalCreateAnswer = this.createAnswer;
              this.createAnswer = function() {
                return originalCreateAnswer.apply(this, arguments).then(answer => {
                  if (answer && answer.sdp) {
                    answer.sdp = sanitizeSDP(answer.sdp);
                  }
                  return answer;
                });
              };
              window.__pbrowser_cloak(this.createAnswer, 'function createAnswer() { [native code] }');

              // 3. Block onicecandidate exposure
              Object.defineProperty(this, 'onicecandidate', {
                set: function(val) {
                  // We accept the listener but never trigger it with real candidates
                },
                get: function() { return null; },
                configurable: true,
                enumerable: true
              });
            }
            
            // Block addIceCandidate for non-relay candidates
            addIceCandidate(candidate) {
              if (candidate && candidate.candidate) {
                const str = candidate.candidate.toLowerCase();
                if (!str.includes('relay')) {
                  return Promise.resolve();
                }
              }
              return super.addIceCandidate(candidate);
            }
          }
          
          window.__pbrowser_cloak(ProxyPeerConnection, 'function RTCPeerConnection() { [native code] }');

          Object.defineProperty(window, 'RTCPeerConnection', {
            value: ProxyPeerConnection,
            writable: false,
            configurable: true
          });
          
          if (window.webkitRTCPeerConnection) {
            Object.defineProperty(window, 'webkitRTCPeerConnection', {
              value: ProxyPeerConnection,
              writable: false,
              configurable: true
            });
          }
        })();
      ''';
    }
  }
}
