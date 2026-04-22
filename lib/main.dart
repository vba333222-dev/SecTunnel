import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Database
import 'package:SecTunnel/core/database/database.dart';
import 'package:SecTunnel/core/database/daos/profile_dao.dart';
import 'package:SecTunnel/core/database/daos/user_script_dao.dart';
import 'package:SecTunnel/repositories/profile_repository.dart';
import 'package:SecTunnel/services/browser/userscript_service.dart';
import 'package:SecTunnel/services/background/headless_keep_alive_service.dart';
import 'package:SecTunnel/services/analytics/privacy_crash_reporter.dart';

// UI
import 'package:SecTunnel/ui/splash/splash_screen.dart';
import 'package:SecTunnel/ui/shared/global_task_overlay.dart';

// Services
import 'package:SecTunnel/services/proxy/modem_rotator_service.dart';
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

Future<String> _getDatabasePath() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return path.join(dbFolder.path, 'pbrowser.db');
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
        ChangeNotifierProvider<ModemRotatorService>(
          create: (_) => ModemRotatorService(),
        ),
      ],
      child: MaterialApp(
        title: 'SecTunnel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueGrey,
            surface: Color(0xFF1E1E1E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
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