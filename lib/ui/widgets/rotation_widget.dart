import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SecTunnel/services/proxy/modem_rotator_service.dart';

class RotationWidget extends StatelessWidget {
  final String profileId;
  final String profileName;

  const RotationWidget({
    Key? key,
    required this.profileId,
    required this.profileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ModemRotatorService>(
      builder: (context, service, child) {
        final state = service.getState(profileId);
        final error = service.getError(profileId);
        final health = service.getHealthScore(profileId);
        final fails = service.getConsecutiveFailures(profileId);
        final cdSeconds = service.getRemainingCooldownSeconds(profileId);
        final ipInfo = service.getIpInfo(profileId);
        final isCoolingDown = cdSeconds > 0;

        final bool isBusy = state == RotationState.connecting || 
                            state == RotationState.rotating || 
                            state == RotationState.validating;

        String healthLabel;
        Color healthColor;
        if (health > 70) {
          healthLabel = 'Healthy';
          healthColor = Colors.green;
        } else if (health >= 40) {
          healthLabel = 'Unstable';
          healthColor = Colors.orange;
        } else {
          healthLabel = 'Poor';
          healthColor = Colors.red;
        }

        String statusText;
        if (state == RotationState.idle && isCoolingDown) {
          if (fails >= 3) {
            statusText = 'IP change is slow. Wait before retrying.\nCooling down (${cdSeconds}s)';
          } else {
            statusText = 'Cooling down (${cdSeconds}s)';
          }
        } else {
          switch (state) {
            case RotationState.idle:
              statusText = 'Ready';
              break;
            case RotationState.connecting:
              statusText = 'Checking current IP...';
              break;
            case RotationState.rotating:
              statusText = 'Rotating IP...';
              break;
            case RotationState.validating:
              statusText = 'Verifying new IP...';
              break;
            case RotationState.success:
              statusText = 'IP Updated';
              break;
            case RotationState.failed:
              if (error == 'ip_not_changed') {
                statusText = 'IP not changed';
              } else if (error == 'validation_failed') {
                statusText = 'Validation failed';
              } else {
                statusText = error ?? 'Rotation Failed';
              }
              break;
          }
        }

        // Evaluate IP quality badge if we have info
        Widget? qualityBadge;
        bool isBadQuality = false;
        if (ipInfo != null) {
          // Re-calculate or just base on the service's logs, 
          // but we can compute it simply here or store the quality label.
          // Since the prompt specifies to show IP, country/ISP and quality badge
          // and warning if BAD.
          int score = 0;
          if (ipInfo.country == 'Indonesia' || ipInfo.country == 'ID') score += 30;
          if (!ipInfo.isProxy) score += 20;
          if (ipInfo.isp != null && ipInfo.isp!.isNotEmpty) score += 20;
          if (ipInfo.latencyMs != null && ipInfo.latencyMs! < 100) score += 30;

          String qLabel;
          Color qColor;
          if (score >= 80) {
            qLabel = 'Good';
            qColor = Colors.green;
          } else if (score >= 50) {
            qLabel = 'OK';
            qColor = Colors.orange;
          } else {
            qLabel = 'Bad';
            qColor = Colors.red;
            isBadQuality = true;
          }

          qualityBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: qColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: qColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: qColor, size: 8),
                const SizedBox(width: 4),
                Text(qLabel, style: TextStyle(color: qColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      profileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: healthColor),
                      ),
                      child: Text(
                        '$healthLabel ($health)',
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (ipInfo != null && !isBusy && state == RotationState.idle) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.public, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(ipInfo.ip, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (qualityBadge != null) qualityBadge,
                          ],
                        ),
                        const SizedBox(height: 4),
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
                        if (isBadQuality) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.warning, size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'IP changed but quality is low',
                                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
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
                        style: TextStyle(
                          color: state == RotationState.failed ? Colors.red : 
                                 state == RotationState.success ? Colors.green : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isBusy || isCoolingDown) ? null : () => service.rotateIp(profileId, profileName),
                    child: Text(
                      isBusy ? 'Processing...' : 
                      isCoolingDown ? 'Wait ${cdSeconds}s' : 'Rotate IP'
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
