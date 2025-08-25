// lib/screens/vocab_drill_screen.dart

import 'package:flutter/material.dart';

class VocabDrillScreen extends StatelessWidget {
  const VocabDrillScreen({Key? key}) : super(key: key);

  Widget _card(String title, List<String> bullets) {
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
                const Text('•  ', style: TextStyle(fontSize: 16)),
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
    const int mastered = 3;
    const int total = 10;
    final double progress = mastered / total;

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
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _card('Foundational Vocabulary', [
              'Basic vocabulary',
              'Essential Grammar',
            ]),
            _card('Topics', ['Daily life', 'Food & drink']),
            _card('Review Deck', [
              'A set of flashcards for reviewing previously learned material',
            ]),
            _card('My Challenge Words', [
              'Words the learner got wrong previously',
            ]),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress: $mastered of $total words mastered',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

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
