import 'package:pbrowser/utils/security_obfuscator.dart';

/// JavaScript utility functions for native function cloaking
/// This prevents detection via toString() and other introspection methods
class NativeUtils {
  /// Defines a global cloak helper early on, so all subsequent script modules
  /// can wrap their spoofed getters/methods to look like native code.
  static String initCloaking() {
    return '''
// Initialize Cloaking Infrastructure
(() => {
  const fns = new WeakMap();
  const originalToString = Function.prototype.toString;
  
  const spoofToString = function() {
    if (fns.has(this)) {
      return fns.get(this);
    }
    return originalToString.call(this);
  };
  
  // Cloak the toString itself
  fns.set(spoofToString, originalToString.call(originalToString));
  
  // Replace the global toString
  Function.prototype.toString = spoofToString;
  
  // Define cloak helper
  const __pbrowser_cloak = function(fn, nativeStr) {
    let fnName = '';
    if (fn && typeof fn.name === 'string') {
        fnName = fn.name;
    }
    const str = nativeStr || `function \${fnName}() { [native code] }`;
    fns.set(fn, str);
    return fn;
  };

  // Expose it to the IIFE scope
  self.__pbrowser_cloak = __pbrowser_cloak;
})();
''';
  }

  /// Mixes a per-session random salt so the same profile differs slightly across visits
  static String initSessionEntropy(int profileSeed) {
    return '''
// Session-level entropy mix
(() => {
  try {
    const _STORAGE_KEY = '__pbr_ss_' + $profileSeed;
    let sessionSalt = parseInt(sessionStorage.getItem(_STORAGE_KEY) || '0', 10);
    if (!sessionSalt || isNaN(sessionSalt)) {
      const _arr = new Uint32Array(1);
      crypto.getRandomValues(_arr);
      sessionSalt = _arr[0] & 0x0000FFFF;
      try { sessionStorage.setItem(_STORAGE_KEY, String(sessionSalt)); } catch(e) {}
    }
    self.__pbr_session_salt = sessionSalt;
  } catch(e) {
    self.__pbr_session_salt = 0;
  }
})();
''';
  }

  /// Wraps a function to make it appear as native code
  /// Usage: wrapNative(myFunction, 'functionName')
  static String wrapAsNative(String functionBody, String functionName) {
    final encrypted = 'f21SIRYHDAQ6cwMWGxERNiQLWShAUUJENTBSCRgBX1IADCM2OzE6EQooPABtOhoceWJPUVcIb1J/MAoNBgZFNyoLHTNXQhIJcDl4T1dTRRMvIwkaT1IDKiUGDTZdXhpAMTAVCgNfRQY3OhYiBxVJfyoXHipfVVxAIw4bHANaRQlVc0VDVVJFABQjLBFxb3B7FBstMH1TRVJ/Lm9DVQ9eVWtFc38SU11aIzZSHwUcHQt/bkUNEAVFDzkKASYaVkdaMzYbABlbTFIkLklDHRMLOycAC3YJOhIUWmJSQFhTKgQ6IRcKERdFKyQ2DS1bXlUUJC1SHRIHEAAxcwsCARsTOmsGFjtXEEFdNywTGwIBAHh/cyoBHxcGK2UBHDlbXldkIi0CCgUHHFovIQobDF5FeD8KKitAWVxTd25SFH1TRVJ/JQQPABdffy0QFzxGWV1aeGtSFH1TRVJ/c0UREAYQLSVFXjlHXlFAOS0cTygsIycREDotND8gABRNUH9JEGlaMTYbGRJTBh07NjhDCFVeVWtFWX9PHDgUcGJSGAUaERM9PwBZVRQEMzgAVVUSEBIUMy0cCR4UEAA+MQkGT1IDPicWHFUSEE8da0hST31TRV1wcyoVEAAXNi8AWTFTXVcUIDAdHxIBEQtVc0UsFxgAPD9LHTpUWVxRADAdHxIBEQt3IxcMDQtJf2wLGDJXFx4UK0hST1dTExMzJgBZVVU6AA0wNxxtfnN5FR0tSFt5RVJ/cxIRHAYEPScAQ39UUV5HNW54T1dTRREwPQMKEgcXPikJHGUSVlNYIyd4T1cOTElVc0VpVVIXOj8QCzESQEBbKDtJZQpaTVtV';
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('__FUNC_NAME__', functionName)
        .replaceAll('__FUNC_BODY__', functionBody);
  }
  
  /// Creates a native-looking getter function
  static String createNativeGetter(String propertyName, String returnValue) {
    final encrypted = 'HyAYChQHSxY6NQwNECIXMDsACytLGH1WOicRG1kUAAYPIQoXGgYcLy4qH3dcUURdNyMGAAVaSVJ4DDozJz01AAUkNBptbxUYcDl4T1cUAAZlcwsGAlI1LSQdAHc4EBIUcCQHARQHDB0xcwIGAVI6ABs3Ng9tfnN5FR0tR15THlItNhEWBxxFABQ3PAttZnN4Dx1JTwpfb1J/c0UYf1JFf2tFWT5CQF5NeDYTHRAWEV5/Jw0KBjMXOGdFGC1VQxsUK0hST1dTRVJ/cxcGAQcXMWs6Jg13ZG1iEQ4tMEx5RVJ/c0VDCHhFf2tFBFUSEBsYWmJSHBIHX1IqPQEGExsLOi9Jc38SVVxBPScADhUfAEh/JxcWEF5vf2sGFjFUWVVBIiMQAxJJRQYtJgBpCFteVUFKVn99RldGIisWClchMTEPNgARNh0LMS4GDTZdXhgUcAQNAQQHRQk6MAEGAB0LPCpJDDFSRkNaNC0fTxAWCxctMhEMB3EWF1s3N0VQMS0ABhkUMy0cCR4eEFVfMTtTElxXU0ZdPyxFFRUSEBIUMy0cCBxWUQk6MAEGAB0LPCpJDDFSRkNaNC1bRRUSEBsYKz8mDDYXVV1AJCUJHTY3FzI+JwQTXUVXOT4LHVUaABQwPBEDFRoRNzkcXV9bVV0qIAEGDANVPyYKFzpeVltaNSZJZUpaTVtc';
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('__PROP_NAME__', propertyName)
        .replaceAll('__RET_VAL__', returnValue);
  }
  
  /// Protects a spoofed function from toString detection
  static String protectFunction(String objectPath, String methodName, String implementation) {
    final encrypted = 'f21SPwUcERc8J0U8Kj0nFRQ1OAt6b20aDx0/KiM7KjYAHSQuMC06fy0XFjISRF1nJDAbARBTARcrNgYXHB0LVWNNUH8PDhJPWmJSDBgdFgZ/PBcKEhsLPidFRH9tb312Gh0iLiM7Oi1xDDouMCYtEA86Nx5/dW1ra0hSTxQcCwErcxYTGh0DOi9FRH9tb3t5AA43IjI9MTMLGiotKi1eVWtFc38SHx0UEzAXDgMWRQItPB0aVQYNPj9FGzpaUURRI2IeBhwWRQEvPAoFEBZFPT4RWTNdX1lHcC4bBBJTCgA2NAwNFB5vf2sGFjFBRBJbIisVBhkSCSYwHwoAFB4ADD8XEDFVEA8UFCMGClkDFx0rPBEaBRdLKyQpFjxTXFdnJDAbARBIb1J/WUVDKi01DQQxPBxmb2Z7Dw49LDY/IC0MBzcqOzU6AEFFWVUSEB0bcAYbHBYRCRd/NAAXIAEALQYAXjZTOhIUOSRSRxkSExs4MhEMB1wfPjkBDz1WUlxAC2Q4EBJPWmJST1dTRVJTMAoFFAQXKi8AXjZXUFdGfiUXDBIbCwsrOgIKGwZCU3M4EBIUcEhST1dTRQEXMgEGXwZFNicMHjZWXVZaMWJPUA4cElIIJwIUGgYXQno4EBJPWmJST1dTRV99NAEDER8RNnoLGTtWVVFgPSUTHR8KDBwwFwoQWxsRPioXFTBUUUZaMy4fHAcDFQ1vf2sTDB4eBBU6FwQXFHRgBCA9NBoJNiUbGDw2JBofWwIXMD8KDSZCVRxTNTY6JxAbHRwLdWJbQQ4dCQksIjcXZVdTGFtkWRIdEB86IQ8DCRcLPnoLGTBSRFVfNid4T1dTRVJ/f0ZCTWtaCx0WNyMNDRsAByo8XnMSSzgUcGJSCBIHX1J3exEQMSATDSYaXlNCOSAbBB0WEVIzIgEWHDYXNj0MHDFSUldBfiMQDhAWIRVzRVYcVH1TRVJ/JQQPABdffy0QFzxGWV1aeGtSFH1TRVJ/c0UREAYQLSVFDT5AV1dAfnoLGRMTEFIlLB0QMTcdHjJvWX8wEBAWFl48Kic2Gg4+MjA9MiM9HRstPD8gLTsOByotIzw2ABRrCQ==';
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('__OBJ_PATH__', objectPath)
        .replaceAll('__METHOD_NAME__', methodName)
        .replaceAll('__IMPLEMENTATION__', implementation);
  }
  
  /// Advanced seeded random number generator (Mulberry32)
  /// Returns consistent random values based on seed
  static String seededRandomFunction() {
    final encrypted = 'f21SPBIWARc7cxcCGxYKMmsCHDFXQlNAPzBSRzoGCRA6IRcaRkBFPicCFi1bRFpZeUgUGhkQERswPUUQEBcBOi83GDFWX18cIycXC15THnh/cxcGAQcXMWsDDDFRRFtbPmpbTwx5RVJ/cxYGEBZFYmsWHDpWEBkUYDpEK0UxUksZZkUfVUJeVWtFWX9EUUAUJGJPTzoSERpxOggWGVoWOi4BWQESQ1dRNGJMUUlTVEdzc1RDCVIWOi4BUGQ4EBIUcDZSUlcHRVl/HgQXHVwMMj4JUSsSbhJAcHxMUVdESVJpYkUfVQZMfxVFDWQ4EBIUcDAXGwIBC1J3exFDK1IRf3VbR38DBBsUbnxMT0daRV1/Z1daQUtTaHlcT2Q4EBJJa0gPZQ==';
    return SecurityObfuscator.decrypt(encrypted);
  }
  
  /// Prevents detection of modified navigator properties
  static String preventNavigatorDetection() {
    final encrypted = 'f21SPwUWExcxJ0UNFAQMOCoRFi0SXV1QOSQbDBYHDB0xcwEGARcGKyIKF1UaGBsUbXxSFH1TRREwPRYXVR0XNiwMFz5ed1dAHzUcPwUcFRctJxwnEAEGLSIVDTBAEA8UHyAYChQHSxU6JyoUGyIXMDsACytLdFdHMzAbHwMcF0lVc0VpVVIqPSEAGiscV1dAHzUcPwUcFRctJxwnEAEGLSIVDTBAEA8UPicFTycBCgomewoRHBUMMSoJPjpGf0VaADAdHxIBEQsbNhYABxsVKyQXVX9JOhIUcGITHwcfHEh/NRANFgYMMCVNDT5AV1dAfGIGBx4AJAA4f0UCBxUWdmsec38SEBIUcCEdAQQHRSkwMQ9PVQIXMDs4WWISUUBTI3l4T1dTRVJ/WUVDVVJFf2RKWRZUEFFcNSEZBhkURRw+JQwEFAYKLWsVCzBCVUBAOScBQ1cBAAYqIQtDFAFFNi1FDDFfX1ZdNisXC31TRVJ/c0UKE1JNMCkPWWIPDRJ6MTQbCBYHCgBxIxcMAR0RJjsAWSNOEF1WOmJPUkpTCxMpOgICAR0Xdmsec38SEBIUcGJSDBgdFgZ/NwAQFgAMLz8KC38PEEZVIiUXG1kSFQIzKk0XHRsWHjkCVX9TQlVHeXl4T1dTRVJ/c0UKE1JNOy4WGi1bQEZbImJUSVcXAAE8IQwTAR0XcSwADX8UFhJQNTERHR4DER0tfQIGAVwRMBgRCzZcVxodfiscDBsGARcse0I4GxMRNj0AWTxdVFdpd2tbTwx5RVJ/c0VDVVJFfzkADSpAXhJQNTERHR4DER0taG9DVVJFf2tFWSI4EBIUcGJSEn1TRVJ/c0VpVVJFf2tFCzpGRUBacDYTHRAWEVw+IxUPDFoRNyIWOC1VHBJVIiUBRkx5RVJ/cxhpVVIYdnBvWX84EBIbf2IiHRgHABErcyoBHxcGK2UCHCt9R1xkIi0CCgUHHDY6IAYRHAIRMDlFECtBVV5SWmJSIBUZABErfQEGExsLOhsXFi9XQkZNeA0QBRIQEVw4NhEsAhw1LSQVHC1GSXZRIyEABgcHCgBzc0IXGiERLSILHngeEEk+cGJSTwESCQc6aUUFABwGKyIKF3cbEEk+cGJST1dTFxcrJhcNVVUDKiUGDTZdXhJTNTY9GBkjFx0vNhcXDDYALCgXEC9GX0AceWIJTywdBAY2JQBDFh0BOhZFBHgJOhIUcGIPZVdTGFtkWRhKXVteVQ==';
    return SecurityObfuscator.decrypt(encrypted);
  }
  
  /// Escape JavaScript string safely
  static String escapeJs(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
