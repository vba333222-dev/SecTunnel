// dart:io removed (unused)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// path import removed (unused)

// Database
import 'package:sec_tunnel/core/database/database.dart';
import 'package:sec_tunnel/core/database/daos/profile_dao.dart';
import 'package:sec_tunnel/core/database/daos/user_script_dao.dart';
import 'package:sec_tunnel/repositories/profile_repository.dart';
import 'package:sec_tunnel/services/browser/userscript_service.dart';
import 'package:sec_tunnel/services/background/headless_keep_alive_service.dart';
import 'package:sec_tunnel/services/analytics/privacy_crash_reporter.dart';

// UI
import 'package:sec_tunnel/ui/splash/splash_screen.dart';
import 'package:sec_tunnel/ui/shared/global_task_overlay.dart';

// Services
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';
import 'package:sec_tunnel/core/logging/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Privacy-Aware Analytics
  await PrivacyCrashReporter.init();
  
  // Load strict backend configurations
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file in main: $e");
  }
  
  HeadlessKeepAliveService.init();

  // Initialize database
  final database = AppDatabase.instance;
  final profileDao = ProfileDao(database);
  final userScriptDao = UserScriptDao(database);
  final profileRepository = ProfileRepository(profileDao);
  final userScriptService = UserScriptService(userScriptDao);

  runApp(PBrowserApp(
    profileRepository: profileRepository,
    userScriptService: userScriptService,
  ));
}



/// Root application widget
class PBrowserApp extends StatelessWidget {
  final ProfileRepository profileRepository;
  final UserScriptService userScriptService;
  
  const PBrowserApp({
    super.key,
    required this.profileRepository,
    required this.userScriptService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProfileRepository>.value(value: profileRepository),
        Provider<UserScriptService>.value(value: userScriptService),
        ChangeNotifierProvider<AppLogger>.value(
          value: AppLogger.instance,
        ),
        ChangeNotifierProvider<ModemRotatorService>(
          create: (_) => ModemRotatorService(),
        ),
      ],
      child: MaterialApp(
        title: 'SecTunnel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Light neutral gray
          colorScheme: ColorScheme.light(
            primary: Colors.blue[600]!,
            surface: Colors.white,
            onSurface: Colors.grey[800]!,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            centerTitle: true,
          ),
        ),
        builder: (context, child) {
          return GlobalTaskOverlay(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}