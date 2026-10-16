import 'package:flutter/material.dart';


import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await SeedService.seedIfEmpty();
  runApp(const GamzApp());
}

class GamzApp extends StatelessWidget {
  const GamzApp({super.key});

  static const String header = 'Igam App';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: header,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
