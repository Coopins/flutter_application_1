import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (best-effort)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // ignore if missing in dev
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // BYPASS_AUTH from --dart-define (accepts true/1/t, case-insensitive)
  const String bypassStr = String.fromEnvironment(
    'BYPASS_AUTH',
    defaultValue: 'false',
  );
  final bool bypass =
      const {'true': true, '1': true, 't': true, 'yes': true}[bypassStr
          .toLowerCase()] ??
      false;

  if (bypass) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.isAnonymous) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  // Log a one-liner so we can see auth state at launch.
  final u = FirebaseAuth.instance.currentUser;
  // ignore: avoid_print
  print(
    'Auth at start -> uid=${u?.uid ?? "(none)"}'
    ', anon=${u?.isAnonymous == true}'
    ', bypass=$bypass',
  );

  // Choose starting route
  final String initialRoute = bypass ? Routes.languageSelection : Routes.main;

  runApp(GabAndGoApp(initialRoute: initialRoute));
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

    // Lock device orientation to portrait (optional)
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      onUnknownRoute:
          (_) => MaterialPageRoute(
            builder: (_) => const HomeScreen(),
            settings: const RouteSettings(name: Routes.home),
          ),
    );
  }
}
