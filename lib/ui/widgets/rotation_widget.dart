import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SecTunnel/services/proxy/modem_rotator_service.dart';
import 'package:SecTunnel/models/ip_info.dart';
import 'package:SecTunnel/models/rotation_log.dart';

/// Displays rotation status, IP quality, health score, and cooldown for a single profile.
/// All state comes from [ModemRotatorService] via Provider. Zero local business logic.
class RotationWidget extends StatelessWidget {
  final String profileId;
  final String profileName;

  const RotationWidget({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ModemRotatorService>(
      builder: (context, service, _) {
        final state = service.getState(profileId);
        final error = service.getError(profileId);
        final health = service.getHealthScore(profileId);
        final fails = service.getConsecutiveFailures(profileId);
        final cdSeconds = service.getRemainingCooldownSeconds(profileId);
        final ipInfo = service.getIpInfo(profileId);
        final isCoolingDown = cdSeconds > 0;
        final isBusy = _isBusy(state);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(health),
                if (ipInfo != null && !isBusy && state == RotationState.idle)
                  _buildIpInfoCard(ipInfo),
                const SizedBox(height: 12),
                _buildStatusRow(state, error, isBusy, isCoolingDown, cdSeconds, fails),
                const SizedBox(height: 16),
                _buildActionButton(service, isBusy, isCoolingDown, cdSeconds),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header: Profile Name + Health Badge ────────────────────

  Widget _buildHeader(int health) {
    final (label, color) = _healthDisplay(health);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          profileName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            '$label ($health)',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ─── IP Info Card with Quality Badge ────────────────────────

  Widget _buildIpInfoCard(IpInfo ipInfo) {
    final score = _calculateScore(ipInfo);
    final quality = IpQuality.fromScore(score);
    final (qLabel, qColor) = _qualityDisplay(quality);
    final isBadQuality = quality == IpQuality.bad;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IP + Quality badge row
            Row(
              children: [
                const Icon(Icons.public, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(ipInfo.ip, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                _QualityBadge(label: qLabel, color: qColor),
              ],
            ),
            const SizedBox(height: 4),
            // Country / ISP row
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${ipInfo.country ?? "Unknown"} / ${ipInfo.isp ?? "Unknown ISP"}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Bad quality warning
            if (isBadQuality) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.warning, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'IP changed but quality is low',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Status Row ─────────────────────────────────────────────

  Widget _buildStatusRow(
    RotationState state,
    String? error,
    bool isBusy,
    bool isCoolingDown,
    int cdSeconds,
    int fails,
  ) {
    final statusText = _resolveStatusText(state, error, isCoolingDown, cdSeconds, fails);
    final statusColor = state == RotationState.failed
        ? Colors.red
        : state == RotationState.success
            ? Colors.green
            : Colors.black87;

    return Row(
      children: [
        if (isBusy) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            'Status: $statusText',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─── Action Button ──────────────────────────────────────────

  Widget _buildActionButton(
    ModemRotatorService service,
    bool isBusy,
    bool isCoolingDown,
    int cdSeconds,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isBusy || isCoolingDown)
            ? null
            : () => service.rotateIp(profileId, profileName),
        child: Text(
          isBusy
              ? 'Processing...'
              : isCoolingDown
                  ? 'Wait ${cdSeconds}s'
                  : 'Rotate IP',
        ),
      ),
    );
  }

  // ─── Pure Display Helpers (no side effects) ─────────────────

  static bool _isBusy(RotationState s) =>
      s == RotationState.connecting ||
      s == RotationState.rotating ||
      s == RotationState.validating;

  static (String, Color) _healthDisplay(int health) {
    if (health > 70) return ('Healthy', Colors.green);
    if (health >= 40) return ('Unstable', Colors.orange);
    return ('Poor', Colors.red);
  }

  static (String, Color) _qualityDisplay(IpQuality quality) {
    switch (quality) {
      case IpQuality.good:
        return ('Good', Colors.green);
      case IpQuality.ok:
        return ('OK', Colors.orange);
      case IpQuality.bad:
        return ('Bad', Colors.red);
      case IpQuality.unknown:
        return ('?', Colors.grey);
    }
  }

  static int _calculateScore(IpInfo info) {
    int score = 0;
    if (info.country == 'Indonesia' || info.country == 'ID') score += 30;
    if (!info.isProxy) score += 20;
    if (info.isp != null && info.isp!.isNotEmpty) score += 20;
    if (info.latencyMs != null && info.latencyMs! < 100) score += 30;
    return score.clamp(0, 100);
  }

  static String _resolveStatusText(
    RotationState state,
    String? error,
    bool isCoolingDown,
    int cdSeconds,
    int fails,
  ) {
    if (state == RotationState.idle && isCoolingDown) {
      return fails >= 3
          ? 'IP change is slow. Wait before retrying.\nCooling down (${cdSeconds}s)'
          : 'Cooling down (${cdSeconds}s)';
    }
    switch (state) {
      case RotationState.idle:
        return 'Ready';
      case RotationState.connecting:
        return 'Checking current IP...';
      case RotationState.rotating:
        return 'Rotating IP...';
      case RotationState.validating:
        return 'Verifying new IP...';
      case RotationState.success:
        return 'IP Updated';
      case RotationState.failed:
        return error ?? 'Rotation Failed';
    }
  }
}

// ─── Small Stateless Sub-Widget ─────────────────────────────────
class _QualityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _QualityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
