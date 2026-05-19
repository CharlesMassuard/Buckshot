import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/home_view.dart';
import 'services/seed_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await seedFirebaseDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buckshot QR Tool',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF9D4EDD),         // Violet Néon
          onPrimary: Colors.white,
          secondary: Color(0xFFFF007F),       // Fuchsia Cyber
          onSecondary: Colors.white,
          error: Color(0xFFFF3366),
          onError: Colors.white,
          background: Color(0xFF0B0914),      // Fond Sombre
          onBackground: Colors.white,
          surface: Color(0xFF161224),
          onSurface: Colors.white,
          surfaceVariant: Color(0xFF241E36),
          onSurfaceVariant: Color(0xFFE0AAFF),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9D4EDD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: const HomeView(),
    );
  }
}