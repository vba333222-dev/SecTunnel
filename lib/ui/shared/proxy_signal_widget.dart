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
      });
      return;
    }

    setState(() => _isLoading = true);
    
    final ms = await ProxyHealthCheckService.checkLatency(widget.config);
    if (mounted) {
      setState(() {
        _latency = ms;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDirect = !widget.config.isConfigured || widget.config.type == ProxyType.none;
    final bool isFailed = _latency < 0;
    
    // Determine bar count and color based on latency
    int bars = 0;
    Color color;

    if (isDirect) {
      bars = 3;
      color = Colors.cyanAccent.shade200; // Special color for direct
    } else if (_isLoading && _latency == 0) {
      bars = 1;
      color = Colors.white38; // Loading state
    } else if (isFailed) {
      bars = 0;
      color = Colors.redAccent.shade400;
    } else if (_latency < 150) {
      bars = 3;
      color = Colors.tealAccent.shade400; // Excellent
    } else if (_latency < 350) {
      bars = 2;
      color = Colors.amberAccent.shade400; // Okay
    } else {
      bars = 1;
      color = Colors.orangeAccent.shade400; // Poor
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── 3 Micro Bars ──────────────────────────────────────────
        Container(
          height: widget.iconSize,
          alignment: Alignment.bottomCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bar 1 (Shortest)
              Container(
                width: 3,
                height: widget.iconSize * 0.45,
                decoration: BoxDecoration(
                  color: bars >= 1 ? color : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: bars >= 1 ? shadow : null,
                ),
              ),
              const SizedBox(width: 2),
              // Bar 2 (Medium)
              Container(
                width: 3,
                height: widget.iconSize * 0.7,
                decoration: BoxDecoration(
                  color: bars >= 2 ? color : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: bars >= 2 ? shadow : null,
                ),
              ),
              const SizedBox(width: 2),
              // Bar 3 (Tallest)
              Container(
                width: 3,
                height: widget.iconSize,
                decoration: BoxDecoration(
                  color: bars >= 3 ? color : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: bars >= 3 ? shadow : null,
                ),
              ),
            ],
          ),
        ),
        
        // ── Label/Latency Text ────────────────────────────────────
        if (widget.showLabel) ...[
          const SizedBox(width: 6),
          Text(
            isDirect 
                ? 'Direct' 
                : isFailed 
                    ? 'Offline' 
                    : _isLoading && _latency == 0
                        ? 'Pinging…'
                        : '${_latency}ms',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDirect 
                  ? color 
                  : isFailed 
                      ? color 
                      : Colors.white70,
              fontFamily: 'monospace', // Tech feel
            ),
          ),
        ],
      ],
    );
  }
}
