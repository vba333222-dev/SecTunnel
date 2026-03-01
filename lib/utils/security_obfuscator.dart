import 'dart:convert';

/// A utility class to obfuscate and de-obfuscate strings (like JavaScript payloads)
/// to prevent easy extraction via reverse engineering (e.g. `strings` command on APK).
class SecurityObfuscator {
  // A simple XOR key. In a real highly-secure environment, this could be generated natively via C++ JNI.
  static const String _key = "PBrowser_Secure_Key_2024";

  /// Encrypts a plaintext string to a Base64 encoded, XOR-masked string.
  /// Use this offline or during development to generate the obfuscated strings.
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return "";
    
    final plainBytes = utf8.encode(plainText);
    final keyBytes = utf8.encode(_key);
    final encryptedBytes = <int>[];

    for (int i = 0; i < plainBytes.length; i++) {
      encryptedBytes.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(encryptedBytes);
  }

  /// Decrypts a Base64 encoded, XOR-masked string back to plaintext.
  /// Use this dynamically at runtime just before JS injection.
  static String decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return "";
    
    try {
      final encryptedBytes = base64Decode(encryptedBase64);
      final keyBytes = utf8.encode(_key);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      // Return empty or throw relying on the caller to handle.
      return "";
    }
  }
}
