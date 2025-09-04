// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart' as fdotenv;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'routes.dart';

// Screens
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/create_account_form_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/fluency_assessment_screen.dart';
import 'screens/lesson_plan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  // Keep all app startup inside a zone for safer error handling
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock device orientation to portrait (optional).
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Load env (no fallback). Throws if missing so we don't run with bad config.
    await fdotenv.dotenv.load(fileName: 'env/.env');

    // Firebase init from FlutterFire CLI generated options.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // BYPASS_AUTH from --dart-define (true/1/t/yes case-insensitive).
    const String bypassStr =
        String.fromEnvironment('BYPASS_AUTH', defaultValue: 'false');
    final bool bypass = const {
          'true': true,
          '1': true,
          't': true,
          'yes': true,
        }[bypassStr.toLowerCase()] ??
        false;

    if (bypass) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.isAnonymous) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    }

    // Quick visibility on auth state at launch.
    final u = FirebaseAuth.instance.currentUser;
    debugPrint(
      'Auth at start -> uid=${u?.uid ?? "(none)"} anon=${u?.isAnonymous == true} bypass=$bypass',
    );

    // Choose starting route
    final String initialRoute = bypass ? Routes.languageSelection : Routes.main;

    runApp(GabAndGoApp(initialRoute: initialRoute));
  }, (error, stack) {
    // Last-resort catch for any uncaught startup/runtime errors
    // (Crashlytics/Sentry can be wired here later if you add them)
    // For now, log to console for visibility.
    // ignore: avoid_print
    print('Uncaught zone error: $error\n$stack');
  });
}

class GabAndGoApp extends StatelessWidget {
  final String initialRoute;
  const GabAndGoApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Gab & Go',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: initialRoute,
      routes: {
        Routes.main: (_) => const MainScreen(),
        Routes.createAccountForm: (_) => const CreateAccountFormScreen(),
        Routes.signIn: (_) => const SignInScreen(),
        Routes.languageSelection: (_) => const LanguageSelectionScreen(),
        Routes.fluency: (_) => const FluencyAssessmentScreen(),
        Routes.lessonPlan: (_) => const LessonPlanScreen(),
        Routes.home: (_) => const HomeScreen(),
        Routes.profile: (_) => const ProfileScreen(),
        Routes.settings: (_) => const SettingsScreen(),
      },
      // Fallback for unknown routes
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: const RouteSettings(name: Routes.home),
      ),
    );
  }
}
