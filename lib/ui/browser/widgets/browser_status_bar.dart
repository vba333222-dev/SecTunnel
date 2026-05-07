import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../browser_controller.dart';

class BrowserStatusBar extends StatelessWidget {
  const BrowserStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final state = controller.state;
    final proxyConfig = controller.profile.proxyConfig;

    if (!controller.hasProxy) return const SizedBox.shrink();

    Color statusColor;
    String statusLabel;
    if (state.isRotating) {
      statusColor = Colors.orangeAccent;
      statusLabel = 'Rotating…';
    } else if (state.isProxyHealthy) {
      statusColor = Colors.greenAccent;
      statusLabel = 'Proxy Active';
    } else {
      statusColor = Colors.redAccent;
      statusLabel = 'Offline';
    }

    final hasRotationUrl = proxyConfig.rotationUrl != null && proxyConfig.rotationUrl!.isNotEmpty;
    final canRotate = hasRotationUrl || proxyConfig.port != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Light Blue/Grey
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor == Colors.greenAccent ? Colors.green.shade700 : statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.router_outlined, size: 14, color: const Color(0xFF5F6368)),
                const SizedBox(width: 6),
                Expanded(
                  child: state.isIpFetching
                      ? SizedBox(
                          height: 10,
                          width: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: statusColor),
                        )
                      : Text(
                          state.currentPublicIp ?? '—',
                          style: const TextStyle(
                            color: Color(0xFF202124),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (state.currentPublicIp != null && !state.isIpFetching)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: state.currentPublicIp!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('IP copied to clipboard'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.copy_rounded, size: 13, color: Color(0xFF9AA0A6)),
                    ),
                  ),
              ],
            ),
          ),
          if (canRotate)
            TextButton.icon(
              onPressed: state.isRotating ? null : controller.rotateIpNow,
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.08),
                foregroundColor: Colors.blueAccent.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: const Size(0, 26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              icon: state.isRotating 
                  ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                  : const Icon(Icons.autorenew_rounded, size: 13),
              label: Text(
                state.isRotating ? 'ROTATING' : 'ROTATE IP',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
