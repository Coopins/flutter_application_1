import 'package:flutter/material.dart';

class AIPracticeScreen extends StatelessWidget {
  const AIPracticeScreen({super.key});

  Widget _colorButton(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {}, // stub for now
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

            // Icon header
            const SizedBox(height: 40),
            const Icon(Icons.person, size: 64, color: Colors.white),
            const SizedBox(height: 40),

            // Colored buttons
            _colorButton(Color(0xFF4A90E2), 'Open-Ended Dialogue'),
            _colorButton(Color(0xFF8E44AD), 'Role-Playing'),
            _colorButton(Color(0xFFF24E4E), 'Free-Form Conversation'),
            _colorButton(Color(0xFFE67E22), 'Storytelling'),
            _colorButton(Color(0xFFF1C40F), 'Explain This To Me'),

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
