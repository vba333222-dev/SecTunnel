import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/services/proxy/proxy_health_check.dart';

/// A dynamic widget that visually indicates proxy health and latency.
/// Shows glowing signal bars (like game ping) based on response time.
class ProxySignalWidget extends StatefulWidget {
  final ProxyConfig config;
  final bool showLabel;
  final double iconSize;

  const ProxySignalWidget({
    super.key,
    required this.config,
    this.showLabel = true,
    this.iconSize = 12.0,
  });

  @override
  State<ProxySignalWidget> createState() => _ProxySignalWidgetState();
}

class _ProxySignalWidgetState extends State<ProxySignalWidget> {
  int _latency = 0;
  bool _isLoading = true;
  String? _externalIp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkLatency();
    
    // Poll every 15 seconds if it's a proxy
    if (widget.config.isConfigured && widget.config.type != ProxyType.none) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkLatency());
    }
  }

  @override
  void didUpdateWidget(covariant ProxySignalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _checkLatency();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLatency() async {
    if (!mounted) return;
    
    // Direct connection always shows 0 latency instantly
    if (!widget.config.isConfigured || widget.config.type == ProxyType.none) {
      setState(() {
        _latency = 0;
        _isLoading = false;
        _externalIp = null;
      });
      return;
    }

    setState(() => _isLoading = true);
    
    final ms = await ProxyHealthCheckService.checkLatency(widget.config);
    if (!mounted) return;
    
    setState(() {
      _latency = ms;
    });

    if (ms >= 0 && _externalIp == null) {
      final ip = await ProxyHealthCheckService.fetchExternalIp(widget.config);
      if (mounted && ip != null) {
        setState(() {
          _externalIp = ip;
          _isLoading = false;
        });
        return;
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDirect = !widget.config.isConfigured || widget.config.type == ProxyType.none;
    final bool isFailed = _latency < 0;
    
    Color color;
    String statusText;

    if (isDirect) {
      color = Colors.cyanAccent.shade200;
      statusText = 'Direct Interface';
    } else if (isFailed) {
      color = Colors.redAccent.shade400;
      statusText = 'Proxy Dead';
    } else if (_isLoading && _externalIp == null) {
      color = Colors.white38;
      statusText = 'Pinging...';
    } else {
      color = Colors.tealAccent;
      statusText = _externalIp != null ? 'Proxy Active: $_externalIp' : 'Proxy Active';
    }

    // Glow effect
    final shadow = [
      BoxShadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: 4,
        spreadRadius: 0.5,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: widget.iconSize * 0.7,
          height: widget.iconSize * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: shadow,
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isFailed ? color : Colors.white70,
            ),
          ),
        ],
      ],
    );
  }
}
