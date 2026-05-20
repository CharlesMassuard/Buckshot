import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'BuckshotTheme.dart';
import 'views/home_view.dart';
import 'views/login_page.dart';
import 'services/seed_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await seedFirebaseDatabase();
  } catch (e) {
    debugPrint("Problème de connexion à FireBase.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buckshot',
      theme: BuckshotTheme.darkTheme,
      home: const LoginView(),
    );
  }
}