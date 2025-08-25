// lib/screens/flashcards_screen.dart

import 'package:flutter/material.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example list of flashcards with word and meaning
    final List<Map<String, String>> cards = [
      {'word': 'hola', 'meaning': 'hello (Spanish greeting)'},
      {'word': 'adiós', 'meaning': 'goodbye'},
      {'word': 'gracias', 'meaning': 'thank you'},
      {'word': 'por favor', 'meaning': 'please'},
      {'word': 'buenos días', 'meaning': 'good morning'},
    ];

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

            // Expandable flashcard list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      collapsedBackgroundColor: Colors.white,
                      backgroundColor: Colors.white,
                      title: Text(
                        card['word']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                card['meaning']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                // TODO: play pronunciation via TTS
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom nav bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Icon(Icons.home, size: 28),
                  ),
                  const Icon(Icons.search, size: 28),
                  const Icon(Icons.person, size: 28),
                  const Icon(Icons.settings, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
