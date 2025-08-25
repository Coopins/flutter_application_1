// lib/screens/language_focus_screen.dart

import 'package:flutter/material.dart';

class LanguageFocusScreen extends StatelessWidget {
  const LanguageFocusScreen({super.key});

  Widget _focusCard(String title, List<String> bullets) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("•  ", style: TextStyle(fontSize: 16)),
                Expanded(child: Text(b, style: const TextStyle(fontSize: 16))),
              ],
            ),
          ),
        ],
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
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gab & Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {}, // stub
                  ),
                ],
              ),
            ),

            // Focus cards
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _focusCard('Vocabulary Focus', [
                      'Keep practicing! Write the numbers from one to ten in Spanish.',
                      'Keep it up! Practice writing the days of the week in Spanish.',
                    ]),
                    _focusCard('Pronunciation Focus', [
                      "You're making progress with pronunciation. Focus on the 'r' sound in words like 'perro' and 'carro' to make it sound more authentic.",
                      'Your pronunciation is getting better! Record yourself speaking and compare it to native speakers to identify areas for refinement.',
                    ]),
                    _focusCard('Grammar Focus', [
                      "You're grasping the basics of sentence structure. Focus on practicing the difference between 'ser' and 'estar' to express yourself more accurately.",
                      'Your grammar is improving! Explore the use of prepositions to add more detail to your descriptions.',
                    ]),
                  ],
                ),
              ),
            ),

            // Bottom nav bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.home, size: 28),
                  Icon(Icons.search, size: 28),
                  Icon(Icons.person, size: 28),
                  Icon(Icons.settings, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
