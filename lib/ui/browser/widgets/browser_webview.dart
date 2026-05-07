import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../browser_controller.dart';

class BrowserWebView extends StatelessWidget {
  const BrowserWebView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final state = controller.state;

    if (!state.isControllerInitialized || !state.isProxyHealthy) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        border: state.isRotating
            ? Border.all(color: Colors.orangeAccent, width: 3.0)
            : Border.all(color: Colors.transparent, width: 0.0),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          controller.injectNativeTouch(details.globalPosition.dx, details.globalPosition.dy);
        },
        child: InAppWebView(
          webViewEnvironment: controller.environment,
          initialUrlRequest: URLRequest(url: WebUri(state.currentUrl)),
          initialSettings: controller.webViewSettings,
          initialUserScripts: UnmodifiableListView<UserScript>(controller.generatedUserScripts),
          onWebViewCreated: controller.onWebViewCreated,
          onLoadStart: controller.onLoadStart,
          onLoadStop: controller.onLoadStop,
          onProgressChanged: controller.onProgressChanged,
          onReceivedError: controller.onReceivedError,
          onReceivedHttpError: controller.onReceivedHttpError,
          onReceivedHttpAuthRequest: controller.onReceivedHttpAuthRequest,
          onReceivedServerTrustAuthRequest: controller.onReceivedServerTrustAuthRequest,
          onReceivedClientCertRequest: controller.onReceivedClientCertRequest,
          shouldInterceptRequest: controller.shouldInterceptRequest,
          shouldInterceptFetchRequest: controller.shouldInterceptFetchRequest,
          shouldOverrideUrlLoading: controller.shouldOverrideUrlLoading,
        ),
      ),
    );
  }
}
