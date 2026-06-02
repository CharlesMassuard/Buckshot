import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:buckshot/buckshot_theme.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await NotificationService().initNotification();
  await NotificationService().checkExactAlarmPermission();

  bool firebaseInitialized = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase non initialisé (ex: si Anton lance sur Linux desktop XD ): $e');
    firebaseInitialized = false;
  }
  runApp( MyApp(isFirebaseReady: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool isFirebaseReady;
  const MyApp({super.key,required this.isFirebaseReady});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buckshot',
      theme: BuckshotTheme.darkTheme,
      // si firebase ne se lance pas 
      home: !isFirebaseReady
        ? const Scaffold(
              backgroundColor: Color(0xFF0B0914),
              body: Center(
                child: Text(
                  "Mode hors-ligne (Firebase désactivé)\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9D4EDD), fontSize: 18),
                ),
              ),
            )
      : StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0B0914),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF9D4EDD)),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomeView();
          }
          return const LoginView();
        },
      ),
    );
  }
}