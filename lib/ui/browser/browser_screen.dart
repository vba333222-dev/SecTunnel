import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'browser_controller.dart';
import 'widgets/browser_topbar.dart';
import 'widgets/browser_status_bar.dart';
import 'widgets/browser_webview.dart';
import 'widgets/browser_loading.dart';
import 'widgets/browser_error.dart';

class BrowserScreen extends StatelessWidget {
  final String profileId;

  const BrowserScreen({
    super.key,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = BrowserController(profileId: profileId, context: context);
        // Start async initialization
        controller.initializeApp();
        return controller;
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Light Mode Base
        body: SafeArea(
          child: Consumer<BrowserController>(
            builder: (context, controller, child) {
              final state = controller.state;
              return Column(
                children: [
                  const BrowserTopBar(),
                  if (controller.hasProxy) const BrowserStatusBar(),
                  Expanded(
                    child: Stack(
                      children: [
                        const BrowserWebView(),
                        
                        // Edge swipe to go back
                        if (state.isControllerInitialized && state.isProxyHealthy)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 24, 
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                                  controller.goBack();
                                }
                              },
                              child: const SizedBox(width: 24),
                            ),
                          ),
                          
                        if (state.isLoading) const BrowserLoading(),
                        if (!state.isProxyHealthy) const BrowserError(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
