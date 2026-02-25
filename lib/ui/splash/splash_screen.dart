import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pbrowser/ui/dashboard/dashboard_screen.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _textFadeController;
  
  @override
  void initState() {
    super.initState();
    
    // The Lottie animation is 300 frames at 60fps = 5.0 seconds total.
    // However, the climax (shield forming) happens around frame 150 (2.5s).
    // We will navigate to the Dashboard automatically after 2.6 seconds.
    _lottieController = AnimationController(
        vsync: this, duration: const Duration(seconds: 5));
    
    _textFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Start Lottie immediately
    _lottieController.forward();
    
    // Wait until the "climax" of the animation (approx 1.5s based on 90 frames of build-up)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Fade in text
    if (mounted) _textFadeController.forward();
    
    // Wait for the shockwave/shield to settle (approx total 2.6 seconds)
    await Future.delayed(const Duration(milliseconds: 1100));
    
    if (mounted) {
      final repo = Provider.of<ProfileRepository>(context, listen: false);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DashboardScreen(repository: repo),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/splash_hero.json',
              controller: _lottieController,
              width: 280,
              height: 280,
              fit: BoxFit.contain,
              frameRate: FrameRate.max,
            ),
            
            // Negative margin to bring text closer to the Lottie bounds
            const SizedBox(height: -20),
            
            FadeTransition(
              opacity: CurvedAnimation(
                  parent: _textFadeController, curve: Curves.easeIn),
              child: const Text(
                'P B R O W S E R',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8.0,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            FadeTransition(
               opacity: CurvedAnimation(
                  parent: _textFadeController, curve: Curves.easeIn),
               child: Text(
                'A N T I - D E T E C T',
                style: TextStyle(
                  color: Colors.tealAccent.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 5.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
