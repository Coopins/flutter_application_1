import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/tts_service.dart';

class LessonPlanScreen extends StatefulWidget {
  final String lessonPlan;

  const LessonPlanScreen({Key? key, required this.lessonPlan})
    : super(key: key);

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
  @override
  void initState() {
    super.initState();
    _speakLessonPlan();
  }

  Future<void> _speakLessonPlan() async {
    // Remove Markdown formatting characters before speaking
    final plainText = widget.lessonPlan.replaceAll(
      RegExp(r'[\#\*\_\`\[\]]'),
      '',
    );

    await TTSService.stop(); // Stop any previous speech
    await TTSService.setDefaults(); // Set speech rate, pitch, etc.
    await TTSService.speak(plainText, lang: 'en-US');
  }

  @override
  void dispose() {
    TTSService.stop(); // Stop speech when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: MarkdownBody(
                  data: widget.lessonPlan,
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    Theme.of(context),
                  ).copyWith(
                    p: const TextStyle(color: Colors.white, fontSize: 16),
                    h1: const TextStyle(color: Colors.white),
                    h2: const TextStyle(color: Colors.white),
                    h3: const TextStyle(color: Colors.white),
                    listBullet: const TextStyle(color: Colors.white),
                    blockquote: const TextStyle(color: Colors.white70),
                    strong: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 40.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text(
                    'Go to Home',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Use your actual Home route name here (e.g., '/home')
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
