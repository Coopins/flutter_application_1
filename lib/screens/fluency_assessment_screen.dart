// lib/screens/fluency_assessment_screen.dart

import 'package:flutter/material.dart';
import '../services/openai_service.dart';

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
  bool _isLoading = false;

  Future<void> _assessFluencyAndGenerateLesson() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final performanceSummary =
          "The user was able to answer basic questions but struggled with complex grammar."; // Placeholder
      final lessonPlan = await _openAIService.generateLessonPlan(
        selectedLanguage: widget.selectedLanguage,
        performanceSummary: performanceSummary,
      );

      Navigator.pushNamed(
        context,
        '/lessonPlan',
        arguments: {'lessonPlan': lessonPlan},
      );
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
        title: const Text("Fluency Assessment"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, size: 80, color: Colors.white),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _assessFluencyAndGenerateLesson,
                      child: const Text("Continue"),
                    ),
                  ],
                ),
      ),
    );
  }
}
