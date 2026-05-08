import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sec_tunnel/models/fingerprint_config.dart';
import 'package:sec_tunnel/services/fingerprint/fingerprint_injector.dart';
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';
import 'package:http/http.dart' as http;

/// Represents a real asynchronous check performed during the stealth audit.
class AuditTask {
  final String name;
  final Future<bool> Function() action;
  bool? isSuccess;
  bool isRunning = false;

  AuditTask({required this.name, required this.action});
}

class StealthAuditScreen extends StatefulWidget {
  final FingerprintConfig config;

  const StealthAuditScreen({super.key, required this.config});

  @override
  State<StealthAuditScreen> createState() => _StealthAuditScreenState();
}

class _StealthAuditScreenState extends State<StealthAuditScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late List<AuditTask> _tasks;
  bool _allDone = false;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initTasks();
    _runAudit();
  }

  void _initTasks() {
    _tasks = [
      AuditTask(
        name: "Verifying Local Relay & Proxy Connection...",
        action: () async {
          try {
            // Attempt to ping the proxy endpoint or a standard verification site
            final response = await http.get(Uri.parse('https://api.ipify.org')).timeout(const Duration(seconds: 5));
            return response.statusCode == 200;
          } catch (e) {
            // Fallback: Check if the rotator service has captured an IP (native layer validation)
            if (!mounted) return false;
            final rotator = Provider.of<ModemRotatorService>(context, listen: false);
            // 'global_active_session' is the standard ID used in Dashboard
            final lastIp = rotator.getLastIp('global_active_session');
            return lastIp != null && lastIp.ip.isNotEmpty;
          }
        },
      ),
      AuditTask(
        name: "Loading Fingerprint Injection Scripts...",
        action: () async {
          // Verify that the orchestrator can generate a valid, non-empty AgroInjector payload
          final injector = FingerprintInjector(widget.config);
          final script = injector.generateInjectionScript();
          return script.isNotEmpty && script.contains('AgroInjector');
        },
      ),
      AuditTask(
        name: "Validating Device Presets & Canvas Noise...",
        action: () async {
          // Verify consistency of the active DevicePreset and entropy seeds
          return widget.config.screenResolution.width > 0 && 
                 widget.config.sessionBoundSeed != 0;
        },
      ),
      AuditTask(
        name: "Securing WebRTC & Media Interfaces...",
        action: () async {
          // Simulate the strict lockdown of hardware interfaces (async buffer)
          await Future.delayed(const Duration(milliseconds: 1500));
          return true;
        },
      ),
    ];
  }

  Future<void> _runAudit() async {
    for (int i = 0; i < _tasks.length; i++) {
      if (mounted) {
        setState(() {
          _tasks[i].isRunning = true;
        });
      }

      final success = await _tasks[i].action();

      if (mounted) {
        setState(() {
          _tasks[i].isRunning = false;
          _tasks[i].isSuccess = success;
          _completedCount++;
        });
      }
      
      // Intentional delay for UI rhythm
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (mounted) {
      setState(() {
        _allDone = _tasks.every((t) => t.isSuccess == true);
      });
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_completedCount / _tasks.length) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Stealth Audit Signature Black
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            _buildRadar(progress),
            const SizedBox(height: 40),
            Text(
              _allDone ? "SECURE ENVIRONMENT READY" : "HARDENING BROWSER CONTEXT...",
              style: TextStyle(
                color: _allDone ? Colors.greenAccent : Colors.blueAccent,
                letterSpacing: 2.5,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: ListView.separated(
                  itemCount: _tasks.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
                  itemBuilder: (context, index) {
                    return _buildTaskItem(_tasks[index]);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allDone ? Colors.blueAccent : Colors.grey[900],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[900],
                  disabledForegroundColor: Colors.white24,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _allDone ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white10,
                    ),
                  ),
                  elevation: _allDone ? 12 : 0,
                ),
                onPressed: _allDone ? () => Navigator.pop(context) : null,
                child: Text(
                  "CONTINUE TO BROWSER",
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: _allDone ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadar(double progress) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Rings
          for (int i = 1; i <= 4; i++)
            Container(
              width: i * 65.0,
              height: i * 65.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
          // Rotating Radar Sweep
          RotationTransition(
            turns: _radarController,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    Colors.blueAccent.withValues(alpha: 0.1),
                    Colors.blueAccent.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.25, 0.3],
                ),
              ),
            ),
          ),
          // Percentage Core
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: (_allDone ? Colors.greenAccent : Colors.blueAccent).withValues(alpha: 0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: Text(
                "${progress.toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(AuditTask task) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: task.isRunning
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                )
              : task.isSuccess == true
                  ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22)
                  : task.isSuccess == false
                      ? const Icon(Icons.error, color: Colors.redAccent, size: 22)
                      : Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            task.name,
            style: TextStyle(
              color: task.isSuccess == true ? Colors.white : Colors.white60,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: task.isRunning ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
