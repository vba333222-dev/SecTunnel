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
              
              // TAMBAHAN: Shield Button dipindah ke sini biar Address Bar lebih lega
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.shield_rounded, color: Colors.blueAccent),
                ),
                title: const Text('Check Anonymity', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Verify IP via Whoer.net', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  controller.webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://whoer.net")));
                },
              ),
              const Divider(color: Colors.white12),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.sync_rounded, color: Colors.tealAccent),
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
                  child: const Icon(Icons.cleaning_services_rounded, color: Colors.orangeAccent),
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
                  child: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  // Back & Forward dipepetin
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 22),
                    onPressed: () => controller.goBack(),
                    splashRadius: 24,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 22),
                    onPressed: () => controller.goForward(),
                    splashRadius: 24,
                  ),
                  
                  // Address Bar yang lebih lega dan tinggi (48px)
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12, width: 1), // Efek border premium
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isProxyHealthy ? Icons.lock_outline_rounded : Icons.lock_open_rounded, 
                            size: 18, 
                            color: state.isProxyHealthy ? Colors.greenAccent : Colors.redAccent
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: controller.urlController,
                              enabled: state.isProxyHealthy && !state.isRotating,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Search or type URL',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.go,
                              onSubmitted: controller.loadUrl,
                            ),
                          ),
                          // Refresh button nempel di dalam text field ala Chrome
                          InkWell(
                            onTap: () => controller.reload(),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Menu Button
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 26),
                    onPressed: () => _showBrowserMenuBottomSheet(context, controller),
                    splashRadius: 24,
                  ),
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