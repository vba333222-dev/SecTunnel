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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Security Menu', style: TextStyle(color: Color(0xFF202124), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.shield_rounded, color: Colors.blueAccent),
                ),
                title: const Text('Check Anonymity', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w600)),
                subtitle: const Text('Verify IP via Whoer.net', style: TextStyle(color: Colors.black54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  controller.webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://whoer.net")));
                },
              ),
              const Divider(height: 1),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.sync_rounded, color: Colors.teal),
                ),
                title: const Text('Rotate IP Address', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w600)),
                subtitle: const Text('Request new IP from modem', style: TextStyle(color: Colors.black54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  controller.rotateIpNow();
                },
              ),
              const Divider(height: 1),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.cleaning_services_rounded, color: Colors.orange),
                ),
                title: const Text('Clear Active Session', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w600)),
                subtitle: const Text('Wipe cookies & local storage', style: TextStyle(color: Colors.black54, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  await controller.clearSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session cache cleared!'), backgroundColor: Colors.black87),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                ),
                title: const Text('Close Profile', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  // Back & Forward
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5F6368), size: 20),
                    onPressed: () => controller.goBack(),
                    splashRadius: 22,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF5F6368), size: 20),
                    onPressed: () => controller.goForward(),
                    splashRadius: 22,
                  ),
                  
                  // Address Bar - Modern & Sleek
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4), // Warm Grey Background
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isProxyHealthy ? Icons.lock_rounded : Icons.lock_open_rounded, 
                            size: 16, 
                            color: state.isProxyHealthy ? Colors.green : Colors.red
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller.urlController,
                              focusNode: controller.urlFocusNode,
                              enabled: state.isProxyHealthy && !state.isRotating,
                              style: const TextStyle(color: Color(0xFF202124), fontSize: 15, fontWeight: FontWeight.w400),
                              decoration: InputDecoration(
                                hintText: 'Search or type URL',
                                hintStyle: const TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                suffixIcon: controller.urlController.text.isNotEmpty 
                                  ? GestureDetector(
                                      onTap: () => controller.urlController.clear(),
                                      child: const Icon(Icons.cancel_rounded, size: 18, color: Colors.black26),
                                    )
                                  : null,
                                suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.go,
                              onSubmitted: (val) {
                                controller.loadUrl(val);
                                controller.urlFocusNode.unfocus();
                              },
                            ),
                          ),
                          if (state.isWebViewLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent.withValues(alpha: 0.6)),
                              ),
                            )
                          else
                            InkWell(
                              onTap: () => controller.reload(),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.refresh_rounded, color: Color(0xFF5F6368), size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Menu Button
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF5F6368), size: 24),
                    onPressed: () => _showBrowserMenuBottomSheet(context, controller),
                    splashRadius: 22,
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