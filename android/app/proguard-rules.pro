# Flutter WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keep class io.flutter.plugins.webviewflutter_android.** { *; }

# HttpOverrides and Proxy classes
-keep class com.example.pbrowser.ProxyHttpOverrides { *; }

# Prevent obfuscation of networking code
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }

# Default Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore missing Play Store classes (deferred components)
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
