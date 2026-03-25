import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:SecTunnel/ui/dashboard/dashboard_screen.dart';
import 'package:SecTunnel/repositories/profile_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this

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


    _lottieController = AnimationController(
        vsync: this, duration: const Duration(seconds: 5));
    
    _textFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));


    _startSequenceAndInit();
  }

  // CHANGE TO SMART FUNCTION
  Future<void> _startSequenceAndInit() async {
    // 1. Run Lottie animation visually
    _lottieController.forward();
    
    // 2. RUN HEAVY PROCESS IN BACKGROUND SIMULTANEOUSLY
    // App will load .env and DB while Lottie plays!
    await Future.wait([
      _initializeBackend(), // Custom function below
      Future.delayed(const Duration(milliseconds: 1500)), // Wait for Lottie climax
    ]);
    
    // 3. Lottie climax reached, show text
    if (mounted) _textFadeController.forward();
    
    // 4. Wait for remaining Lottie aesthetic time
    await Future.delayed(const Duration(milliseconds: 1100));
    
    // 5. Move to Dashboard smoothly
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

  // ANTI-DETECT ENGINE INITIALIZATION FUNCTION
  Future<void> _initializeBackend() async {
    try {
      // Load Environment Variables (VPS IP & Password)
      await dotenv.load(fileName: ".env");
      
      // If you have Database initialization (Drift/SQLite), put it here
      // await MyDatabase.initialize();
      
    } catch (e) {
      debugPrint("Failed to load system: $e");
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
    // Scaffold dengan latar belakang gelap total
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Solid Black
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // SEMENTARA: Lottie murni di tengah layar
            // Karena Lottie Anda sudah berisi animasi fingerprint dan teks v1.2.2, 
            // kita hapus semua text widget buatan Flutter agar tidak overlap.
            SizedBox(
              width: 250,
              height: 250,
              child: Lottie.asset(
                'assets/lottie/splash_hero.json',
                controller: _lottieController, // _lottieController dikelola di initState
                fit: BoxFit.contain, // Memastikan Lottie tidak terpotong
              ),
            ),
          ],
        ),
      ),
    );
  }
} 