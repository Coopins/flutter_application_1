// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/create_account_form_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/fluency_assessment_screen.dart';
import 'screens/lesson_plan_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/vocab_drill_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/ai_practice_screen.dart';
import 'screens/language_focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/logout_screen.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gab & Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
      routes: {
        '/createAccount': (ctx) => const CreateAccountScreen(),
        '/createForm': (ctx) => const CreateAccountFormScreen(),
        '/payment': (ctx) => const PaymentScreen(),
        '/languageSelect': (ctx) => const LanguageSelectionScreen(),
        '/fluencyAssessment': (ctx) => const FluencyAssessmentScreen(),
        '/lessonPlan': (ctx) => const LessonPlanScreen(),
        '/flashcards': (ctx) => const FlashcardsScreen(),
        '/vocabDrill': (ctx) => const VocabDrillScreen(),
        '/calendar': (ctx) => const CalendarScreen(),
        '/fluency': (ctx) => const AIPracticeScreen(),
        '/languageTests': (ctx) => const LanguageFocusScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/logout': (ctx) => const LogoutScreen(),
        '/login':
            (ctx) =>
                const Scaffold(body: Center(child: Text('Login Placeholder'))),
      },
    );
  }
}
