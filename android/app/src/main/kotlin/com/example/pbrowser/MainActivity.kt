package com.example.pbrowser

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.webkit.ProxyController
import androidx.webkit.ProxyConfig
import androidx.webkit.WebViewFeature
import android.os.Bundle
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.pbrowser/proxy"
    private val TAG = "PBrowserProxy"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setProxy") {
                val host = call.argument<String>("host")
                val port = call.argument<Int>("port")
                
                if (host != null && port != null) {
                    try {
                        setGlobalProxy(host, port)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error setting proxy: ${e.message}")
                        // Return success null to prevent app crash on Flutter side
                        result.success(null) 
                    }
                } else {
                    result.error("INVALID_ARGS", "Host or port missing", null)
                }
            } else if (call.method == "setProfileDirectory") {
                val profileId = call.argument<String>("profileId")
                if (profileId != null) {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            android.webkit.WebView.setDataDirectorySuffix(profileId)
                            Log.i(TAG, "WebView data directory suffix set to: $profileId")
                        } else {
                            Log.w(TAG, "setDataDirectorySuffix requires API level 28+")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error setting data directory suffix: ${e.message}")
                        result.error("WEBVIEW_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Profile ID missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setGlobalProxy(host: String, port: Int) {
        if (WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE)) {
            try {
                val proxyConfig = ProxyConfig.Builder()
                    .addProxyRule("$host:$port")
                    .addBypassRule("*.workers.dev")
                    .addBypassRule("secureverify.job-anggaajie.workers.dev")
                    .addBypassRule("<local>")
                    .build()
                
                // Use the main executor (UI thread) effectively for the callback
                val executor = ContextCompat.getMainExecutor(this)

                ProxyController.getInstance().setProxyOverride(proxyConfig, executor, {
                    Log.i(TAG, "Proxy applied successfully: $host:$port")
                })
            } catch (e: Exception) {
                Log.e(TAG, "Failed to apply proxy override: ${e.message}")
            }
        } else {
            Log.w(TAG, "WebViewFeature.PROXY_OVERRIDE not supported on this device.")
        }
    }
}
