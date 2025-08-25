import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _go(BuildContext context, String route) async {
    HapticFeedback.selectionClick();
    try {
      await Navigator.pushNamed(context, route);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                  '/lessonPlan',
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
                  '/fluency',
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
                  '/languageSelection',
                ),
              ],
            ),

            const Spacer(),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.home, size: 28),
                    ),
                  ),
                  const Icon(Icons.search, size: 28),
                  const Icon(Icons.person, size: 28),
                  InkWell(
                    onTap: () => _go(context, '/logout'),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.settings, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
