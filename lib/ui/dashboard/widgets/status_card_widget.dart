import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';

class StatusCardWidget extends StatelessWidget {
  final String profileId;

  const StatusCardWidget({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final rotator = context.watch<ModemRotatorService>();
    final ipInfo = rotator.getIpInfo(profileId);
    final health = rotator.getHealthScore(profileId);
    final state = rotator.getState(profileId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'CURRENT IP',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildNetworkBadge(state, health),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isBusy(state)
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.white,
                            child: Container(
                              height: 28,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          )
                        : Text(
                            ipInfo?.ip ?? 'Unknown',
                            key: ValueKey<String>(ipInfo?.ip ?? 'Unknown'),
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              _buildHealthIndicator(health),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildDetailItem(
                    icon: Icons.public,
                    label: 'Location',
                    value: ipInfo?.country ?? 'N/A',
                    isLoading: _isBusy(state),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildDetailItem(
                    icon: Icons.business,
                    label: 'ISP',
                    value: ipInfo?.isp ?? 'N/A',
                    isLoading: _isBusy(state),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildDetailItem(
                    icon: Icons.speed,
                    label: 'Latency',
                    value: ipInfo?.latencyMs != null ? '${ipInfo!.latencyMs}ms' : 'N/A',
                    isLoading: _isBusy(state),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSessionInfo(rotator),
          if (state == RotationState.failed)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rotator.getError(profileId) ?? 'Rotation failed',
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static bool _isBusy(RotationState s) =>
      s == RotationState.connecting ||
      s == RotationState.rotating ||
      s == RotationState.validating;

  Widget _buildNetworkBadge(RotationState state, int health) {
    Color color;
    String text;
    if (_isBusy(state)) {
      color = Colors.amber[600]!;
      text = 'Reconnecting';
    } else if (health == 0 || state == RotationState.failed) {
      color = Colors.red[500]!;
      text = 'Disconnected';
    } else {
      color = Colors.green[500]!;
      text = 'Connected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(int health) {
    Color color = Colors.green[500]!;
    if (health < 40) {
      color = Colors.red[400]!;
    } else if (health < 70) {
      color = Colors.amber[500]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(Icons.monitor_heart, color: color, size: 16),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$health%',
                key: ValueKey<int>(health),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Health Score',
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required String value, required bool isLoading}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.white,
                        child: Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        key: ValueKey<String>(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo(ModemRotatorService rotator) {
    final logs = rotator.getProfileLogs(profileId, 5); // Fetch a few to find the last success
    final lastLog = logs.where((l) => l.isSuccess).firstOrNull;
    
    String lastRotatedText = 'Never';
    if (lastLog != null) {
      final diff = DateTime.now().difference(lastLog.timestamp);
      if (diff.inMinutes == 0) {
        lastRotatedText = 'Just now';
      } else {
        lastRotatedText = '${diff.inMinutes}m ago';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              'Last rotated: $lastRotatedText',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
