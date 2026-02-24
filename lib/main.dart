import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Database
import 'package:pbrowser/core/database/database.dart';
import 'package:pbrowser/core/database/daos/profile_dao.dart';
import 'package:pbrowser/repositories/profile_repository.dart';

// UI
import 'package:pbrowser/ui/dashboard/dashboard_screen.dart';
import 'package:pbrowser/ui/shared/global_task_overlay.dart';

// Services
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = await _initializeDatabase();
  final profileDao = ProfileDao(database);
  final profileRepository = ProfileRepository(profileDao);

  runApp(PBrowserApp(profileRepository: profileRepository));
}

/// Initialize Drift database
Future<AppDatabase> _initializeDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = path.join(dbFolder.path, 'pbrowser.db');
  final executor = NativeDatabase(File(dbPath));
  
  debugPrint('[Database] Initialized at: $dbPath');
  return AppDatabase(executor);
}

/// Root application widget
class PBrowserApp extends StatelessWidget {
  final ProfileRepository profileRepository;
  
  const PBrowserApp({
    super.key,
    required this.profileRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProfileRepository>.value(value: profileRepository),
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
        home: DashboardScreen(repository: profileRepository),
      ),
    );
  }
}
