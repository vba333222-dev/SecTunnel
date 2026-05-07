# ------------------------------------------------------------------------------
# SecTunnel Production-Grade ProGuard / R8 Hardening Rules
# ------------------------------------------------------------------------------

# 1. Obfuscation Level
-optimizationpasses 5
-allowaccessmodification
-repackageclasses ''

# 2. Keep Essential Flutter Infrastructure
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }

# 3. SecTunnel Native Entry Points (Keep only what is necessary)
-keep class com.example.pbrowser.MainActivity { *; }
# Keep the generated Flutter registration class
-keep class com.example.pbrowser.GeneratedPluginRegistrant { *; }

# 4. INTERNAL LOGIC OBFUSCATION (The "Sealing" part)
# We remove the broad -keep for com.example.pbrowser.**
# This allows R8 to rename all internal services, models, and utility classes.

# 5. Native JNI Communication
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# 6. WebView & Javascript Interface (CRITICAL: Do NOT obfuscate @JavascriptInterface)
-keep class androidx.webkit.** { *; }
-keep class android.webkit.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 7. Reflection Support for Plugins
-keepattributes Signature,Exceptions,*Annotation*,InnerClasses,EnclosingMethod

# 8. Remove Debug Logs from Bytecode (Side-channel prevention)
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# 9. JSON & Models (If using reflection for serialization)
# Keep names for classes that might be serialized via MethodChannel
-keepclassmembernames class com.example.pbrowser.models.** { *; }
