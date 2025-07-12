// lib/screens/fluency_assessment_screen.dart

import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import '../services/lesson_plan_storage.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  final String selectedLanguage;

  const FluencyAssessmentScreen({Key? key, required this.selectedLanguage})
    : super(key: key);

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  final OpenAIService _openAIService = OpenAIService();
  final TextEditingController _responseController = TextEditingController();
  bool _isLoading = false;

  Future<void> _assessFluencyAndGenerateLesson() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final performanceSummary = _responseController.text.trim();

      final lessonPlan = await _openAIService.generateLessonPlan(
        selectedLanguage: widget.selectedLanguage,
        performanceSummary: performanceSummary,
      );

      // Save the lesson plan for later use
      LessonPlanStorage.saveLessonPlan(lessonPlan);

      // Navigate to lesson plan screen
      Navigator.pushNamed(context, '/lessonPlan');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fluency Assessment'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Describe your language skills briefly below:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _responseController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your response here...',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _assessFluencyAndGenerateLesson,
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
