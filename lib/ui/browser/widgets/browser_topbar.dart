import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../browser_controller.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserTopBar extends StatelessWidget {
  const BrowserTopBar({super.key});

  void _showBrowserMenuBottomSheet(BuildContext context, BrowserController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111115),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white12, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Security Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.swap_horiz_rounded, color: Colors.tealAccent),
                ),
                title: const Text('Rotate IP Address', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Request new IP from modem', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  controller.rotateIpNow();
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.orangeAccent),
                ),
                title: const Text('Clear Active Session', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Wipe cookies & local storage', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  await controller.clearSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session cache cleared!')));
                  }
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close_rounded, color: Colors.redAccent),
                ),
                title: const Text('Close Profile', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final state = controller.state;

    return Container(
      color: const Color(0xFF111111),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
                    onPressed: () => controller.goBack(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                    onPressed: () => controller.goForward(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.lock, size: 14, color: state.isProxyHealthy ? Colors.greenAccent : Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller.urlController,
                              enabled: state.isProxyHealthy && !state.isRotating,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.go,
                              onSubmitted: controller.loadUrl,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.reload(),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.shield_rounded, color: Colors.tealAccent, size: 22),
                    tooltip: 'Check Anonymity',
                    onPressed: () {
                      controller.webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://whoer.net")));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 22),
                    onPressed: () => _showBrowserMenuBottomSheet(context, controller),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // Progress Bar
            if (state.isWebViewLoading && state.isProxyHealthy)
              LinearProgressIndicator(
                value: state.progress,
                minHeight: 2,
                color: Colors.blueAccent,
                backgroundColor: Colors.transparent,
              )
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
