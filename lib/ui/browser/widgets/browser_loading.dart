import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../browser_controller.dart';
import 'package:sec_tunnel/ui/shared/themed_lottie.dart';

class BrowserLoading extends StatelessWidget {
  const BrowserLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final state = controller.state;

    if (!state.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThemedLottie(
              animation: LottieAnimation.connecting,
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Running Pre-Flight Security Checks...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
