import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../browser_controller.dart';
import 'package:sec_tunnel/ui/shared/themed_lottie.dart';
import 'package:sec_tunnel/models/browser_profile.dart';

class BrowserError extends StatelessWidget {
  final bool isConnectionError;
  final BrowserProfile? profile;

  const BrowserError({
    super.key,
    this.isConnectionError = false,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final state = controller.state;
    final proxyConfig = profile?.proxyConfig;

    if (state.isProxyHealthy && !state.hasConnectionError) {
      return const SizedBox.shrink();
    }

    final hasRotationUrl = proxyConfig?.rotationUrl != null && proxyConfig!.rotationUrl!.isNotEmpty;

    return Container(
      color: Colors.white.withValues(alpha: 0.9), // Glassy white overlay
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ThemedLottie(
                    animation: LottieAnimation.connectionError,
                    width: 80,
                    height: 80,
                    repeat: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isConnectionError ? 'Connection Interrupted' : 'Connection Failed',
                    style: const TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorReason ?? 'Proxy tunnel is currently unreachable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (hasRotationUrl) ...[
                    _ActionTile(
                      icon: Icons.autorenew_rounded,
                      iconColor: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                      title: 'Rotate IP & Retry',
                      subtitle: 'Fresh start with a new modem identity',
                      onTap: controller.rotateAndRetry,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _ActionTile(
                    icon: Icons.refresh_rounded,
                    iconColor: Colors.grey.shade700,
                    bgColor: Colors.grey.shade100,
                    title: 'Quick Reconnect',
                    subtitle: 'Keep current IP and try again',
                    onTap: controller.retryConnection,
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.public_rounded,
                    iconColor: Colors.orange.shade700,
                    bgColor: Colors.orange.shade50,
                    title: 'Bypass Proxy',
                    subtitle: 'Browse with real IP (unsafe)',
                    onTap: controller.bypassProxyAndLoad,
                    outlined: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: outlined ? iconColor.withValues(alpha: 0.2) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF202124),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
