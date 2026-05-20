import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'views/home_view.dart';
import 'services/seed_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase non initialisé (ex: si Anton lance sur Linux desktop XD ): $e');
  }

  await initializeDateFormatting('fr_FR', null);

  //await seedFirebaseDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buckshot QR Tool',
      theme: BuckshotTheme.darkTheme,
      home: const HomeView(),
    );
  }
}