import 'package:SecTunnel/models/fingerprint_config.dart';
import 'package:SecTunnel/utils/security_obfuscator.dart';

/// JavaScript code generator for WebGL fingerprint spoofing
class WebGLSpoof {
  static String generate(FingerprintConfig config) {
    final vendor = _escapeJs(config.webglConfig.vendor);
    final renderer = _escapeJs(config.webglConfig.renderer);
    
    final encrypted = 'f21SUkpOWE9/BCAhMj5FDBsqNhl7fnUUbX9PUkp5TVp2c1hdVQlvf2sGFjFBRBJTNTYiDgUSCBcrNhdDSFIyOikiNQ1XXlZRIiscCDQcCwY6KxFNBQAKKyQRAC9XHlVRJBITHRYeAAY6IV5pVVJvf2syHD11fGBRPiYXHR4dAjEwPREGDQZLLzkKDTBGSUJRfiUXGycSFxMyNhEGB1JYfy0QFzxGWV1aeDITHRYeAAY6IUxDDnhFf2tFVnASZXx5ERE5KjMsMzcRFyoxKiUgHQwpc38SEBJdNmJaHxYBBB86JwARVU9YYmtWTmsGBRsUK0hST1dTRVItNhEWBxxFeG8THDFWX0ATa0hST1dTGHh/c0VDf1JFf2tKVn9nfn91Awk3KyghIDwbFjcmJy0yGgkiNVUSEBIUOSRSRwcSFxMyNhEGB1JYYnZFSmgGBAQdcDl4T1dTRVJ/IQAXAAALf2xBCzpcVFdGNTBVVH1TRVJ/Lm9DVVJFVWtFWX9AVUZBIixSCBIHNRMtMggGARcXcSoVCTNLGEZcOTFeTxYBAgcyNgsXBlteVWtFBGQ4EBI+cGJdQFcyCQEwcwoVEAAXNi8AWTldQhJjNSA1I0V5RVI2NUVLAQsVOiQDWQhXUnV4YhAXARMWFxsxNCYMGwYAJz9FWGIPEBVBPiYXCR4dABZ4ekUYf1JFf2sGFjFBRBJTNTYiDgUSCBcrNhdRVU9FCC4HPhMAYldaNCcABhkUJh0xJwAbAVwVLSQRFitLQFcaNycGPxYBBB86JwARTnhFf2tFc38SEBJjNSA1I0UhABw7NhcKGxUmMCURHCdGHkJGPzYdGw4DAFw4NhEzFAAEMi4RHC0SDRJSJSwRGx4cC1ovMhcCGBcROjlMWSQ4EBIUcGJSBhFTTQI+IQQOEAYALWtYRGISAwUAZHdbTwx5RVJ/c0VDVVIXOj8QCzESFxZCNSwWAAVUXnh/c0VDVVIYVWtFWX8SEFtScGoCDgUSCBcrNhdDSE9Yf3hSTWsEGRJPWmJST1dTRVJ/IQAXAAALf2xBCzpcVFdGNTBVVH1TRVJ/c0Uef1JFf2tFWS1XREdGPmIVCgMjBAA+PgAXEABXcSoVCTNLGEZcOTFeTxYBAgcyNgsXBlteVWtFWX9PCzgUcD94El5bTElV';
    
    return SecurityObfuscator.decrypt(encrypted)
        .replaceAll('\$vendor', vendor)
        .replaceAll('\$renderer', renderer);
  }
  
  static String _escapeJs(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }
}
