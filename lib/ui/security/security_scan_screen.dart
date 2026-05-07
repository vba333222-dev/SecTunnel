import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sec_tunnel/models/fingerprint_config.dart';
import 'package:sec_tunnel/services/fingerprint/self_test_service.dart';

class SecurityScanScreen extends StatefulWidget {
  final FingerprintConfig config;

  const SecurityScanScreen({super.key, required this.config});

  @override
  State<SecurityScanScreen> createState() => _SecurityScanScreenState();
}

class _SecurityScanScreenState extends State<SecurityScanScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  final SelfTestService _testService = SelfTestService();
  
  bool _isScanning = true;
  SelfTestResult? _result;
  
  final List<String> _visibleLogs = [];
  final ScrollController _logScrollController = ScrollController();
  Timer? _logTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startScan();
  }

  Future<void> _startScan() async {
    try {
      // Start the actual test
      final resultFuture = _testService.runFullAudit(widget.config);
      
      // Simulate fake logs for effect while waiting
      const startupLogs = [
        "Initializing SecTunnel Stealth Engine...",
        "Hooking WebGL Rendering Context...",
        "Applying Prototype Cloaking...",
        "Masking WebRTC Stack...",
        "Injecting Entropy Seeds...",
        "Scanning for potential leaks...",
      ];

      int logIndex = 0;
      _logTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
        if (logIndex < startupLogs.length) {
          _addLog(startupLogs[logIndex]);
          logIndex++;
        } else {
          timer.cancel();
        }
      });

      final result = await resultFuture;
      
      // Add real results to logs
      for (var log in result.logs) {
        await Future.delayed(const Duration(milliseconds: 200));
        _addLog(log);
      }

      if (mounted) {
        setState(() {
          _result = result;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _addLog(String msg) {
    if (mounted) {
      setState(() {
        _visibleLogs.add("> $msg");
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _logTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Stealth Audit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Radar Section
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRadarCircles(),
                RotationTransition(
                  turns: _radarController,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          Colors.blue.withValues(alpha: 0.5),
                          Colors.blue,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.25, 0.3],
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isScanning ? Colors.blue.withValues(alpha: 0.2) : (_result?.score ?? 0) > 80 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: _isScanning ? Colors.blue.withValues(alpha: 0.5) : (_result?.score ?? 0) > 80 ? Colors.green : Colors.red,
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: _isScanning 
                        ? const Icon(Icons.shield_outlined, color: Colors.blue, size: 48)
                        : Text(
                            "${_result?.score ?? 0}%",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Text(
            _isScanning ? "SCANNING FINGERPRINT..." : "AUDIT COMPLETE",
            style: TextStyle(
              color: _isScanning ? Colors.blue : Colors.green,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Result Details (Score Breakdown)
          if (!_isScanning && _result != null) _buildScoreBreakdown(),

          const SizedBox(height: 24),
          
          // Terminal Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _visibleLogs.length,
                itemBuilder: (context, index) {
                  final log = _visibleLogs[index];
                  final isFail = log.contains("FAIL");
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isFail ? Colors.redAccent : Colors.greenAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (!_isScanning) 
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("CONTINUE TO BROWSER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadarCircles() {
    return Stack(
      children: List.generate(4, (index) {
        return Container(
          width: (index + 1) * 60.0,
          height: (index + 1) * 60.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
        );
      }),
    );
  }

  Widget _buildScoreBreakdown() {
    if (_result == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Consistency", _result!.breakdown['consistency'] ?? 0),
          _buildStatItem("Realism", _result!.breakdown['realism'] ?? 0),
          _buildStatItem("Stealth", _result!.breakdown['stealth'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          "$value%",
          style: TextStyle(
            color: value > 80 ? Colors.green : (value > 50 ? Colors.orange : Colors.red),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
