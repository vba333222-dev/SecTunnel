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
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.pbrowser/proxy"
    private val TAG = "PBrowserProxy"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setProxy") {
                val host = call.argument<String>("host")
                val port = call.argument<Int>("port")
                val scheme = call.argument<String>("scheme")
                
                if (host != null && port != null) {
                    try {
                        setGlobalProxy(host, port, scheme)
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
                // ... logic remains
                if (profileId != null) {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            android.webkit.WebView.setDataDirectorySuffix(profileId)
                            Log.i(TAG, "WebView data directory suffix set to: $profileId")
                            result.success(true)
                        } else {
                            Log.w(TAG, "setDataDirectorySuffix requires API level 28+")
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to set WebView data directory suffix: ${e.message}")
                        // IllegalStateException if WebView was already instantiated or suffix already set
                        result.success(false)
                    }
                } else {
                    result.error("INVALID_ARGS", "Profile ID missing", null)
                }
            } else if (call.method == "injectTouch") {
                val rawX = call.argument<Double>("x")?.toFloat() ?: 0f
                val rawY = call.argument<Double>("y")?.toFloat() ?: 0f
                
                try {
                    val density = resources.displayMetrics.density
                    val x = rawX * density
                    val y = rawY * density
                    
                    val rootView: View = window.decorView.rootView
                    val downTime = SystemClock.uptimeMillis()
                    val eventTime = downTime + 50
                    
                    // Dispatch ACTION_DOWN
                    val downEvent = MotionEvent.obtain(downTime, downTime, MotionEvent.ACTION_DOWN, x, y, 0)
                    rootView.dispatchTouchEvent(downEvent)
                    downEvent.recycle()

                    // Dispatch ACTION_UP
                    val upEvent = MotionEvent.obtain(downTime, eventTime, MotionEvent.ACTION_UP, x, y, 0)
                    rootView.dispatchTouchEvent(upEvent)
                    upEvent.recycle()
                    
                    Log.i(TAG, "Injected native touch at: $x, $y")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to inject native touch: ${e.message}")
                    result.success(false)
                }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setGlobalProxy(host: String, port: Int, scheme: String?) {
        if (WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE)) {
            try {
                // Prepend scheme to enforce protocol (e.g. SOCKS5) preventing DNS leaks
                val proxyUrl = if (scheme?.lowercase() == "socks5") {
                    "socks5://$host:$port"
                } else {
                    "$host:$port"
                }

                val proxyConfig = ProxyConfig.Builder()
                    .addProxyRule(proxyUrl)
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
