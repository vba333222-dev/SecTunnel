import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Database
import 'package:pbrowser/core/database/database.dart';
import 'package:pbrowser/core/database/daos/profile_dao.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:pbrowser/services/browser/userscript_service.dart';
import 'package:pbrowser/services/background/headless_keep_alive_service.dart';
import 'package:pbrowser/services/analytics/privacy_crash_reporter.dart';

// UI
import 'package:pbrowser/ui/splash/splash_screen.dart';
import 'package:pbrowser/ui/shared/global_task_overlay.dart';

// Services
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Privacy-Aware Analytics
  await PrivacyCrashReporter.init();
  
  HeadlessKeepAliveService.init();

  // Initialize database
  final database = await _initializeDatabase();
  final profileDao = ProfileDao(database);
  final profileRepository = ProfileRepository(profileDao);
  final userScriptService = UserScriptService(database.userScriptDao);

  runApp(PBrowserApp(
    profileRepository: profileRepository,
    userScriptService: userScriptService,
  ));
}

/// Initialize Drift database with SQLCipher (AES-256)
Future<AppDatabase> _initializeDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = path.join(dbFolder.path, 'pbrowser.db');
  
  // Manage secure key
  const storage = FlutterSecureStorage();
  const keyName = 'pbrowser_db_key';
  
  String? key = await storage.read(key: keyName);
  
  if (key == null) {
    // Generate a secure 32-byte (256 bit) random key
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    // Store as Base64 encoded string
    key = base64Encode(bytes);
    await storage.write(key: keyName, value: key);
    debugPrint('[Security] Generated new hardware-backed AES-256 key');
  }

  // Create encrypted native database
  final executor = NativeDatabase.createInBackground(
    File(dbPath),
    setup: (db) {
      db.execute("PRAGMA key = '$key';");
      debugPrint('[Database] SQLCipher PRAGMA encryption unlocked');
    },
  );
  
  debugPrint('[Database] Securely initialized at: $dbPath');
  return AppDatabase(executor);
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
        title: 'PBrowser',
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
