import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';
import 'package:sec_tunnel/models/rotation_log.dart';
import 'package:intl/intl.dart';

class ActivityLogWidget extends StatelessWidget {
  final String profileId;

  const ActivityLogWidget({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final rotator = context.watch<ModemRotatorService>();
    final logs = rotator.getProfileLogs(profileId, 5);

    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey<int>(logs.length),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[100],
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildLogItem(log);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(RotationLog log) {
    final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.isSuccess ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.isSuccess ? Icons.check : Icons.close,
              color: log.isSuccess ? Colors.green[600] : Colors.red[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.isSuccess ? 'Rotated successfully' : 'Rotation failed',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.isSuccess 
                      ? '${log.oldIp ?? '?'} → ${log.newIp ?? '?'}' 
                      : log.error ?? 'Unknown error',
                  style: TextStyle(
                    color: log.isSuccess ? Colors.grey[600] : Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
