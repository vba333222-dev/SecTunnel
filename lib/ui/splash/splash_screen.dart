import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pbrowser/ui/dashboard/dashboard_screen.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Tambahkan ini

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

  // UBAH JADI FUNGSI PINTAR
  Future<void> _startSequenceAndInit() async {
    // 1. Jalankan animasi Lottie secara visual
    _lottieController.forward();
    
    // 2. JALANKAN PROSES BERAT DI LATAR BELAKANG SECARA BERSAMAAN
    // Aplikasi akan memuat .env dan DB sambil Lottie berputar!
    await Future.wait([
      _initializeBackend(), // Fungsi buatan kita di bawah
      Future.delayed(const Duration(milliseconds: 1500)), // Tunggu climax Lottie
    ]);
    
    // 3. Climax Lottie tercapai, munculkan teks
    if (mounted) _textFadeController.forward();
    
    // 4. Tunggu sisa waktu estetika pelindung Lottie selesai
    await Future.delayed(const Duration(milliseconds: 1100));
    
    // 5. Pindah ke Dashboard dengan mulus
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

  // FUNGSI INISIALISASI MESIN ANTI-DETECT
  Future<void> _initializeBackend() async {
    try {
      // Muat Environment Variables (Server VPS IP & Password)
      await dotenv.load(fileName: ".env");
      
      // Jika Anda punya inisialisasi Database (Drift/SQLite), taruh di sini
      // await MyDatabase.initialize();
      
    } catch (e) {
      debugPrint("Gagal memuat sistem: $e");
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
      backgroundColor: const Color(0xFF111111), 
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: Lottie.asset(
                'assets/lottie/splash_hero.json',
                controller: _lottieController,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.15,
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: _textFadeController, curve: Curves.easeIn),
                child: Column(
                  children: [
                    const Text(
                      'S E C T U N N E L',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'V 1.2.2',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 