import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../browser_controller.dart';
import 'package:sec_tunnel/ui/shared/themed_lottie.dart';

class BrowserError extends StatelessWidget {
  const BrowserError({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final state = controller.state;
    final proxyConfig = controller.profile.proxyConfig;

    if (state.isProxyHealthy) {
      return const SizedBox.shrink();
    }

    final hasRotationUrl = proxyConfig.rotationUrl != null && proxyConfig.rotationUrl!.isNotEmpty;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A28),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: ThemedLottie(
                      animation: LottieAnimation.connectionError,
                      width: 72,
                      height: 72,
                      repeat: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proxy Connection Failed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              controller.profile.name,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorReason ?? 'Could not reach the proxy server. The modem may be resetting or the credentials are incorrect. What would you like to do?',
                    style: TextStyle(
                      color: state.errorReason != null ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 16),
                  if (hasRotationUrl) ...[
                    _ActionTile(
                      icon: Icons.swap_horiz_rounded,
                      iconColor: Colors.tealAccent,
                      bgColor: Colors.tealAccent.withValues(alpha: 0.10),
                      title: 'Rotate IP Now',
                      subtitle: 'Request a new IP from the modem, then retry',
                      onTap: controller.rotateAndRetry,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _ActionTile(
                    icon: Icons.refresh_rounded,
                    iconColor: Colors.purpleAccent,
                    bgColor: Colors.purpleAccent.withValues(alpha: 0.10),
                    title: 'Retry Connection',
                    subtitle: 'Re-check proxy health and reconnect',
                    onTap: controller.retryConnection,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.public_rounded,
                    iconColor: Colors.amberAccent,
                    bgColor: Colors.amberAccent.withValues(alpha: 0.08),
                    title: 'Open Without Proxy',
                    subtitle: 'Browse using your real IP (anonymity reduced)',
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outlined ? iconColor.withValues(alpha: 0.35) : iconColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: outlined ? iconColor.withValues(alpha: 0.08) : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: outlined ? iconColor : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
