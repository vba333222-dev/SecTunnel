import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum LottieAnimation {
  loading('assets/lottie/loading.json'),
  dashboardEmpty('assets/lottie/dashboard_empty.json'),
  connecting('assets/lottie/connecting.json'),
  splashHero('assets/lottie/splash_hero.json'),
  networkLoading('assets/lottie/network_loading.json'),
  emptyProfiles('assets/lottie/empty_profiles.json'),
  actionSuccess('assets/lottie/action_success.json'),
  connectionError('assets/lottie/connection_error.json');

  final String path;
  const LottieAnimation(this.path);
}

/// A wrapper widget to consistently render Lottie animations with the app's aesthetic.
class ThemedLottie extends StatelessWidget {
  final LottieAnimation animation;
  final double width;
  final double height;
  final BoxFit fit;
  final bool repeat;

  const ThemedLottie({
    super.key,
    required this.animation,
    this.width = 150,
    this.height = 150,
    this.fit = BoxFit.contain,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        animation.path,
        fit: fit,
        repeat: repeat,
        frameRate: FrameRate.max,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Lottie load error: $error');
          return const Icon(
            Icons.broken_image_rounded,
            color: Colors.white24,
            size: 40,
          );
        },
      ),
    );
  }
}
