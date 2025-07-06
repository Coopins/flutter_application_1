import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  const FluencyAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  late String selectedLanguage;
  final OpenAIService _aiService = OpenAIService();

  String? _lessonPlan;
  bool _isLoading = false;
  bool _hasInteractedWithAI = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      selectedLanguage = args;
    } else {
      selectedLanguage = 'Spanish'; // fallback to prevent crashes
    }
  }

  Future<void> _startFluencyAssessment() async {
    setState(() {
      _isLoading = true;
      _lessonPlan = null;
    });

    try {
      final result = await _aiService.generateLessonPlan(
        selectedLanguage: selectedLanguage,
        performanceSummary:
            "I'm a beginner but can understand a few basic phrases.",
      );

      setState(() {
        _lessonPlan = result;
        _isLoading = false;
        _hasInteractedWithAI = true;
      });
    } catch (e) {
      setState(() {
        _lessonPlan = 'Failed to generate lesson plan.\n$e';
        _isLoading = false;
        _hasInteractedWithAI = false;
      });
    }
  }

  void _goHome() {
    Navigator.pushNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Fluency Assessment',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap the mic to begin your short fluency assessment.',
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : IconButton(
                  icon: const Icon(Icons.mic, size: 60, color: Colors.white),
                  onPressed: _startFluencyAssessment,
                ),
            const SizedBox(height: 30),
            if (_lessonPlan != null && !_isLoading)
              Column(
                children: [
                  const Text(
                    'AI Lesson Plan Ready!',
                    style: TextStyle(fontSize: 16, color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 10),
                  // Uncomment this to show the full lesson plan:
                  // Text(_lessonPlan!, style: TextStyle(color: Colors.white)),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _hasInteractedWithAI ? _goHome : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
