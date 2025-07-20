import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  final String selectedLanguage;

  const FluencyAssessmentScreen({Key? key, required this.selectedLanguage})
    : super(key: key);

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  bool _isListening = false;
  String _transcript = '';
  String _lessonPlan = '';

  @override
  void initState() {
    super.initState();
    _requestMicPermissionAndStart();
  }

  Future<void> _requestMicPermissionAndStart() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _startListening();
    } else {
      setState(() {
        _transcript = "Microphone permission denied.";
      });
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });

    // Simulated delay for transcription
    await Future.delayed(const Duration(seconds: 3));

    String mockTranscript =
        "I'm a beginner learning ${widget.selectedLanguage}.";

    setState(() {
      _isListening = false;
      _transcript = mockTranscript;
    });

    _generateLessonPlan(mockTranscript);
  }

  Future<void> _generateLessonPlan(String input) async {
    // Simulated delay for GPT generation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _lessonPlan =
          "Lesson Plan for ${widget.selectedLanguage}:\n"
          "1. Basic Greetings\n"
          "2. Common Phrases\n"
          "3. Numbers 1-10\n"
          "4. Simple Questions";
    });
  }

  Widget _buildListeningView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.mic, size: 80, color: Colors.green),
        SizedBox(height: 20),
        Text(
          "Gabi is listening...",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        _lessonPlan.isNotEmpty ? _lessonPlan : "Transcript: $_transcript",
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isListening ? _buildListeningView() : _buildResultView(),
      ),
    );
  }
}
