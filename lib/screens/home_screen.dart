// lib/screens/home_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/routes.dart';
import 'package:flutter_application_1/services/lesson_plan_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    try {
      navigator.pushNamed(route);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screen not available yet. Check route in main.dart'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    double iconSize = 48,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _go(context, route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Debug-only Firestore smoke test: creates a sample lesson plan and shows the new doc ID.
  Future<void> _debugSavePlanSmoke(BuildContext context) async {
    try {
      final id = await LessonPlanStorage.savePlan(
        markdown: '# Test Plan\n\nHello world.',
        language: 'Spanish',
        ttsLocale: 'es-ES',
      );
      HapticFeedback.lightImpact();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved test plan with id: $id'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving test plan: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // Floating debug button only visible in debug/profile builds.
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () => _debugSavePlanSmoke(context),
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Save Plan'),
            )
          : null,

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Gab & Go',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                _tile(
                  context,
                  Icons.menu_book,
                  'My Lesson Plan',
                  Routes.lessonPlan,
                ),
                _tile(context, Icons.view_module, 'Flashcards', '/flashcards'),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _tile(
                  context,
                  Icons.bar_chart,
                  'Language Tests',
                  '/languageTests',
                ),
                _tile(
                  context,
                  Icons.chat_bubble,
                  'Fluency Practice',
                  Routes.fluency,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _tile(
                  context,
                  Icons.play_circle_fill,
                  'Active Lessons',
                  '/activeLessons',
                  iconSize: 54,
                ),
                _tile(
                  context,
                  Icons.translate,
                  'Language Selection',
                  Routes.languageSelection,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),

      // Bottom bar stays safe-area aware.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: Colors.white,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  tooltip: 'Home',
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  icon: const Icon(Icons.home, size: 28, color: Colors.black),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search coming soon')),
                    );
                  },
                  icon: const Icon(Icons.search, size: 28, color: Colors.black),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => _go(context, Routes.profile),
                  icon: const Icon(Icons.person, size: 28, color: Colors.black),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => _go(context, Routes.settings),
                  icon: const Icon(
                    Icons.settings,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
