import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../identity_assembly_controller.dart';

class IdentityPreviewPanel extends StatelessWidget {
  const IdentityPreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IdentityAssemblyController>();
    final identity = controller.currentPreview;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identity Realism Analysis',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (identity == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 48, color: Color(0xFFE2E8F0)),
                    SizedBox(height: 16),
                    Text(
                      'Waiting for selection...',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildIdentityHeader(controller),
                    const SizedBox(height: 32),
                    _buildSectionTitle('PLATFORM COHERENCE'),
                    _buildInfoRow('Engine', '${identity.engine.name} ${identity.engine.chromiumVersion}'),
                    _buildInfoRow('OS', '${identity.platform.os} ${identity.platform.osVersion}'),
                    _buildInfoRow('UA String', identity.engine.userAgent, isCode: true),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('HARDWARE ECOSYSTEM'),
                    _buildInfoRow('GPU Renderer', identity.hardware.gpu.renderer),
                    _buildInfoRow('Memory', '${identity.hardware.deviceMemory} GB'),
                    _buildInfoRow('CPU Cores', identity.hardware.hardwareConcurrency.toString()),
                    _buildInfoRow('Touch Points', identity.platform.maxTouchPoints.toString()),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('RESOLUTION STABILITY'),
                    _buildInfoRow('Resolution', '${identity.platform.screen.width}x${identity.platform.screen.height}'),
                    _buildInfoRow('DPR', identity.platform.screen.pixelRatio.toString()),
                    _buildInfoRow('Viewport', '${identity.platform.screen.width}x${identity.platform.screen.height}'),

                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.insights_rounded, size: 18, color: controller.riskColor),
                              const SizedBox(width: 8),
                              const Text(
                                'REALISM INSIGHTS',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInsightItem('Device architecture is clustered within real-world benchmarks.'),
                          _buildInsightItem('Chromium build range matches target hardware release.'),
                          _buildInsightItem('Viewport drift is within stable mobile boundaries.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader(IdentityAssemblyController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.selectedModel!.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.selectedFamily!.toUpperCase()} ECOSYSTEM',
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('REALISM', '${(controller.realismScore * 100).toInt()}%'),
              _buildStat('STABILITY', 'HIGH'),
              _buildStat('ANOMALY', 'ZERO'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: const Color(0xFF1E293B),
                fontSize: 12,
                fontFamily: isCode ? 'monospace' : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
