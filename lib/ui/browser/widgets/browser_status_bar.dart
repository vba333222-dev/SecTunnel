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
      color: const Color(0xFF1A1A28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.router_outlined, size: 14, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Expanded(
                  child: state.isIpFetching
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: statusColor),
                        )
                      : Text(
                          state.currentPublicIp ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.copy_rounded, size: 14, color: Colors.white.withValues(alpha: 0.45)),
                    ),
                  ),
              ],
            ),
          ),
          if (canRotate)
            ElevatedButton.icon(
              onPressed: state.isRotating ? null : controller.rotateIpNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: state.isRotating 
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent))
                  : const Icon(Icons.swap_horiz_rounded, size: 14),
              label: Text(
                state.isRotating ? 'Rotating' : 'Rotate',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
