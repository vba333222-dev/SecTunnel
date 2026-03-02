# ------------------------------------------------------------------------------
# PBrowser Custom ProGuard / R8 Rules
# ------------------------------------------------------------------------------

# 1. PBrowser Native Classes (MainActivity, ProxyHttpOverrides, dll)
-keep class com.example.pbrowser.** { *; }
-keepclassmembers class com.example.pbrowser.** { *; }

# 2. Native JNI Communication (Krusial untuk injeksi Fingerprint / Proxy / Low-level bypass)
# Mencegah R8 menghapus atau mengganti nama fungsi native JNI
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# 3. Flutter MethodChannel & Plugin Registration
# Mencegah MethodChannel terhapus saat rilis
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 4. WebView Plugin & AndroidX WebKit (Browser API, ProxyController, CookieManager)
# Mencegah crash pada Proxy Controller dan injeksi WebView
-keep class androidx.webkit.** { *; }
-keep class android.webkit.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keep class io.flutter.plugins.webviewflutter_android.** { *; }

# Memastikan JavascriptInterface tidak diobfuscate (Krusial untuk komunikasi WebView <-> Native)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 5. Networking Core
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }

# 6. Ignore missing Play Store classes (deferred components)
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
