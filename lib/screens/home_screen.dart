// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  label,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),

            // Top row: My Lesson Plan & Flashcards
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
            const SizedBox(height: 40),

            // Bottom row: Language Tests & Fluency Practice
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

            const Spacer(),

            // Bottom navigation bar (static except home & settings)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home icon returns to MainScreen
                  InkWell(
                    onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.home, size: 28),
                    ),
                  ),
                  // Search icon remains static
                  const Icon(Icons.search, size: 28),
                  // Person icon remains static/profile placeholder
                  const Icon(Icons.person, size: 28),
                  // Settings icon now navigates to LogoutScreen
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/logout'),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
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
