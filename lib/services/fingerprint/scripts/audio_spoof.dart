import 'package:SecTunnel/models/fingerprint_config.dart';
import 'package:SecTunnel/services/fingerprint/scripts/utils.dart';
import 'package:SecTunnel/utils/security_obfuscator.dart';

/// JavaScript code generator for AudioContext fingerprint spoofing
/// CRITICAL: Uses deterministic seeding based on Profile ID for consistency
class AudioSpoof {
  static String generate(FingerprintConfig config) {
    // Use canvas noise salt as deterministic seed
    final seed = config.canvasNoiseSalt.hashCode;
    
    final encrypted = 'f21SUkpOWE9/EjAnPD1FHAQrLRpqZBJnAA09KT49IlJ3FyA3MCAoFgUsKgt7cxsUbX9PUkp5TVp2c1hdVQlvf2sGFjFBRBJEIi0UBhsWNhc6N0VeVVYWOi4BQlUSEDgUcB0tPDI2ITcbDDciOzYqEhQ6c38SOhIUf21SJhkaERs+PwwZEFIWOi4BHDsSQlNaNC0fTxAWCxctMhEMB3hFfygKFyxGEFVRJBATARMcCFJicxYGEBYAOxkEFztdXRpEIi0UBhsWNhc6N0xYf1JFVWtFVnASY0ZbIidSAAUaAhsxMglDNAcBNiQmFjFGVUpAWmJSDBgdFgZ/HBcKEhsLPickDDtbX3FbPjYXFwNTWFIoOgsHGgVLHj4BEDBxX1xANToGTwsPRQU2PQEMAlwSOikOECtzRVZdPwEdAQMWHQZkWUVDf1JFNi1FUX59QltTOSwTAzYGARswEAoNARcdK2JFCzpGRUBaa0hST31TRV1wcyoVEAAXNi8AWR5HVFtbEy0cGxILEVI8PAsQAQAQPD8KC1USEFRBPiEGBhgdRSEvPAoFEBYkKi8MFhxdXkZRKDZaQVldBAA4IExDDnhFf2tFGjBcQ0YUMy0cGxILEVJicwsGAlIqLSICEDFTXHNBNCsdLBgdERcnJ01NW1wELSwWUGQ4EBIUcEhST1dTSl1/ABEMBxdFMDkMHjZcUV4UMzAXDgMWJBw+PxwQEABvf2tFWTxdXkFAcC0ABhAaCxMzEBcGFAYAHiUEFSZBVUAUbWIRABkHAAorfQYREBMROgoLGDNLQ1dGfiAbARNbBh0xJwAbAVteVWtFWX84EBIUcG1dTzgFAAAtOgEGVREXOioRHB5cUV5NIycATwAaERp/NwAXEAAINiUMCitbUxJaPysBCn1TRVJ/DDozJz0xGggxJhxgdXNgFR0zITY/PCEaATo8f1JFf2tFWX8SEEBRJDcAAVcQChwrNh0XTnhFfzZvWX84EBIbf2IxAAcKRQItPBUGBwYMOjhFHy1dXRJbIisVBhkSCVI8PAsQAQAQPD8KC1USEGFEPy0UChMyEBY2PCYMGwYAJz9LCS1dRF1AKTIXT0pTKgA2NAwNFB4kKi8MFhxdXkZRKDZcHwUcER0rKhUGTnhFf0FFWXAdEH9VOydSDBgdFgYtJgYXGgBFMyQKEn9cUUZdJid4T1c8Bxg6MBFNERcDNiUAKS1dQFdGJDtaPAccChQ6NyQWERsKHCQLDTpKRB4UdzYdPAMBDBw4dElDDnhFf2tFDz5eRVcOcCQHARQHDB0xe0xDDnhFf2tFWX9AVUZBIixSIAUaAhsxMgkiABYMMAgKFytXSEYaJC0hGwUaCxV3el5pVVJFfzZvWX9PGQk+cGJ4T1dcSlINNhUPFBEAfywJFj1TXBJ1JSYbADQcCwY6KxFpVVISNiUBFigccUdQOS0xABkHAAorc1hDJgIKMC0AHR5HVFtbEy0cGxILEUlVc0UKE1JNKCILHTBFHkVRMikbGzYGARswEAoNARcdK2JFAlUSEBIUJyscCxgESwU6MQ4KATMQOyIKOjBcRFdMJGJPTyQDCh05NgEiABYMMAgKFytXSEYPWmJSEn0OTFp2aG8=';
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('\$seed', seed.toString())
        .replaceAll('__SEEDED_RANDOM__', NativeUtils.seededRandomFunction())
        .replaceAll('__PROTECT_CREATE_ANALYSER__', NativeUtils.protectFunction(
          'context',
          'createAnalyser',
          '''
function() {
  const analyser = originalCreateAnalyser();
  
  // Store original methods
  const originalGetFloatFrequencyData = analyser.getFloatFrequencyData.bind(analyser);
  const originalGetByteFrequencyData = analyser.getByteFrequencyData.bind(analyser);
  const originalGetFloatTimeDomainData = analyser.getFloatTimeDomainData.bind(analyser);
  const originalGetByteTimeDomainData = analyser.getByteTimeDomainData.bind(analyser);
  
  // Reset random for consistency
  const localRandom = seededRandom(profileSeed + 1000);
  
  // Override getFloatFrequencyData
  analyser.getFloatFrequencyData = function(array) {
    originalGetFloatFrequencyData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = (localRandom() - 0.5) * 0.0001;
      array[i] += noise;
    }
  };
  
  // Override getByteFrequencyData
  analyser.getByteFrequencyData = function(array) {
    originalGetByteFrequencyData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = Math.floor((localRandom() - 0.5) * 2);
      array[i] = Math.max(0, Math.min(255, array[i] + noise));
    }
  };
  
  // Override getFloatTimeDomainData
  analyser.getFloatTimeDomainData = function(array) {
    originalGetFloatTimeDomainData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = (localRandom() - 0.5) * 0.00001;
      array[i] += noise;
    }
  };
  
  // Override getByteTimeDomainData
  analyser.getByteTimeDomainData = function(array) {
    originalGetByteTimeDomainData(array);
    
    // Add deterministic noise
    for (let i = 0; i < array.length; i++) {
      const noise = Math.floor((localRandom() - 0.5) * 2);
      array[i] = Math.max(0, Math.min(255, array[i] + noise));
    }
  };
  
  return analyser;
}
'''
        ));
  }
}
