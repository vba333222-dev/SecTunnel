import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbrowser/models/proxy_config.dart';

enum ModemStatus {
  online,
  offline,
  rotating,
}

/// Service to monitor a physical modem (e.g. Huawei E3372h) or proxy IP changes.
/// Prevents the browser from leaking real IPs during a connection drop or IP rotation.
class ModemRotatorService {
  final ProxyConfig proxyConfig;
  
  // Huawei E3372h typical HiLink API endpoint for checking WAN IP / status
  // For generic proxies, replacing this with an external IP checker might be needed.
  static const String _huaweiApiUrl = 'http://192.168.8.1/api/monitoring/status';
  
  Timer? _pollingTimer;
  final ValueNotifier<ModemStatus> statusNotifier = ValueNotifier(ModemStatus.offline);
  
  bool _isDisposed = false;

  ModemRotatorService({required this.proxyConfig});

  /// Starts monitoring the modem connection status
  void startMonitoring({Duration interval = const Duration(seconds: 3)}) {
    _isDisposed = false;
    // Initial check
    _checkStatus();
    
    // Setup polling
    _pollingTimer = Timer.periodic(interval, (_) => _checkStatus());
  }

  /// Stops monitoring the modem
  void stopMonitoring() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkStatus() async {
    if (_isDisposed) return;
    
    try {
      // If we are strictly routed through a proxy, we need to ensure this check
      // either traverses the proxy or checks the local modem gateway.
      // Usually, HiLink APIs (192.168.8.1) need to bypass the proxy.
      // Our Android ProxyConfig bypasses <local>, allowing this HTTP call.
      
      // Simulating the check since we cannot guarantee the hardware API structure here.
      // In production, parse XML from _huaweiApiUrl: <ConnectionStatus>901</ConnectionStatus>
      final response = await http.get(
        Uri.parse(_huaweiApiUrl),
        // Timeout very fast to detect dropped connection instantly
        headers: {'Accept': 'text/xml'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        // Connected to Modem Gateway. Now verify if it actually has WAN internet.
        // Assuming the XML response indicates '901' for connected.
        if (response.body.contains('<ConnectionStatus>901</ConnectionStatus>')) {
          _updateStatus(ModemStatus.online);
        } else {
          _updateStatus(ModemStatus.rotating);
        }
      } else {
        _updateStatus(ModemStatus.offline);
      }
    } catch (e) {
      // Timeout or connection refused means the modem is physically disconnected or rebooting
      _updateStatus(ModemStatus.offline);
    }
  }

  void _updateStatus(ModemStatus newStatus) {
    if (_isDisposed) return;
    if (statusNotifier.value != newStatus) {
      statusNotifier.value = newStatus;
      debugPrint('[ModemRotator] Status changed to: \${newStatus.name}');
    }
  }
  
  void dispose() {
    stopMonitoring();
    statusNotifier.dispose();
  }
}
