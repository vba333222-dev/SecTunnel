import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:webview_flutter/webview_flutter.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(HeadlessTaskHandler());
}

class HeadlessTaskHandler extends TaskHandler {
  WebViewController? _controller;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // We are now running in a background isolate but with Flutter engine access.
    // Initialize Headless WebView
    debugPrint('[KeepAlive] Starting Background Headless WebView');
    
    // Note: Due to limitations with flutter_foreground_task and WebView on Android,
    // true "Headless WebViews" from isolates can be tricky. However, by initializing
    // the controller here, we attempt to keep the engine busy.
    // A fully independent headless webview requires a platform view which isn't available
    // strictly in an isolate without a FlutterView, but creating the controller binds
    // the underlying AndroidWebView which might stay alive if WakeLocks are held.

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              debugPrint('[KeepAlive] Background Page loaded: $url');
              // Setup a heartbeat
              _startHeartbeat();
            },
            onWebResourceError: (error) {
              debugPrint('[KeepAlive] Background Web resource error: ${error.description}');
            },
          ),
        );
      
      // We start it on a proxy testing or safe url just to spin it up.
      // In a real implementation this would receive the URL and ProfileID via data.
      await _controller?.loadRequest(Uri.parse('https://whoer.net/ip'));
    } catch (e) {
      debugPrint('[KeepAlive] Failed to start Headless WebView: $e');
    }
  }

  void _startHeartbeat() {
    // Keep JS engine ticking
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _controller?.runJavaScript("console.log('Keep-Alive Heartbeat');");
      FlutterForegroundTask.updateService(
        notificationTitle: 'SecTunnel Keep-Alive',
        notificationText: 'Background session running... (Heartbeat active)',
      );
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called periodically based on eventAction
    debugPrint('[KeepAlive] Event tick');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Clean up
    debugPrint('[KeepAlive] Background Headless WebView stopped');
    _controller = null;
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}

class HeadlessKeepAliveService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pbrowser_keep_alive',
        channelName: 'SecTunnel Background Service',
        channelDescription: 'Maintains headless webview connections while app is minimized.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startHeadlessSession(String profileId, String profileName) async {
    // Check and request Notification Permission for Android 13+
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Check and request Battery Optimization Exception
    // Crucial for long-running headless WebViews on Android
    final bool isIgnoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!isIgnoring) {
      debugPrint('[KeepAlive] Requesting ignore battery optimization...');
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final success = await FlutterForegroundTask.startService(
      notificationTitle: 'SecTunnel ($profileName)',
      notificationText: 'Background farming active...',
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'STOP'),
      ],
      callback: startCallback,
    );
    
    return success is ServiceRequestSuccess;
  }

  static Future<bool> stopHeadlessSession() async {
    return (await FlutterForegroundTask.stopService()) is ServiceRequestSuccess;
  }
}
