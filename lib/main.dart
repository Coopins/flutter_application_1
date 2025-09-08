import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'routes.dart';

// Screens (no args)
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/create_account_form_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/lesson_plan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

// Screen with args
import 'screens/fluency_assessment_screen.dart' as fl;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env for OPENAI_API_KEY
  try {
    await dotenv.load(fileName: 'env/.env');
  } catch (e) {
    // Don't crash if file missing; service will error with a clear message.
    debugPrint('dotenv load error: $e');
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Optional dev bypass: flutter run --dart-define=BYPASS_AUTH=true
  const bypassAuth = bool.fromEnvironment('BYPASS_AUTH', defaultValue: false);
  if (bypassAuth && FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
  }

  runApp(const GabAndGoApp());
}

class GabAndGoApp extends StatelessWidget {
  const GabAndGoApp({super.key});

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

      // Simple routes
      routes: {
        Routes.main: (_) => const MainScreen(),
        Routes.home: (_) => const HomeScreen(),
        Routes.signIn: (_) => const SignInScreen(),
        Routes.createAccountForm: (_) => const CreateAccountFormScreen(),
        Routes.languageSelection: (_) => const LanguageSelectionScreen(),
        Routes.lessonPlan: (_) => const LessonPlanScreen(),
        Routes.profile: (_) => const ProfileScreen(),
        Routes.settings: (_) => const SettingsScreen(),
      },

      // Routes with args
      onGenerateRoute: (settings) {
        if (settings.name == Routes.fluency) {
          String? language;
          final args = settings.arguments;
          if (args is Map) {
            final tl = (args['targetLanguage'] ?? args['language']);
            if (tl is String && tl.trim().isNotEmpty) language = tl.trim();
          }
          if (language == null) {
            return MaterialPageRoute(
              builder: (_) => const LanguageSelectionScreen(),
              settings: const RouteSettings(name: Routes.languageSelection),
            );
          }
          return MaterialPageRoute(
            builder:
                (_) => fl.FluencyAssessmentScreen(targetLanguage: language!),
            settings: settings,
          );
        }
        return null;
      },

      onUnknownRoute:
          (_) => MaterialPageRoute(
            builder: (_) => const MainScreen(),
            settings: const RouteSettings(name: Routes.main),
          ),

      initialRoute: Routes.main,
    );
  }
}
