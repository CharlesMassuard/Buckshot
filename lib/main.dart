import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:buckshot/buckshot_theme.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/event_detail_view.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

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

  try {
    await NotificationService().initNotification(
      onNotificationClick: (String? eventId) {
        if (eventId != null && eventId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _performSecureNavigation(eventId);
          });
        }
      },
    );
    await NotificationService().checkExactAlarmPermission();
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation des notifications : $e');
  }

  runApp(MyApp(isFirebaseReady: firebaseInitialized));
}

void _performSecureNavigation(String eventId) {
  if (MyApp.navigatorKey.currentState != null) {
    MyApp.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => EventDetailView(eventId: eventId),
      ),
    );
  } else {
    Future.delayed(const Duration(milliseconds: 200), () => _performSecureNavigation(eventId));
  }
}

class MyApp extends StatelessWidget {
  final bool isFirebaseReady;
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key, this.isFirebaseReady = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Buckshot',
      theme: BuckshotTheme.darkTheme,
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