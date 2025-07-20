import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  final String selectedLanguage;

  const FluencyAssessmentScreen({Key? key, required this.selectedLanguage})
    : super(key: key);

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isListening = false;
  String _lessonPlan = '';
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _startAssessmentFlow();
  }

  Future<void> _startAssessmentFlow() async {
    setState(() {
      _isListening = true;
      _lessonPlan = '';
      _showRetry = false;
    });

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() {
        _lessonPlan = "Microphone permission denied.";
        _isListening = false;
        _showRetry = true;
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath = path.join(dir.path, 'input.wav');

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
      path: filePath,
    );

    await Future.delayed(const Duration(seconds: 5));

    final recordedPath = await _recorder.stop();

    if (recordedPath == null || !File(recordedPath).existsSync()) {
      setState(() {
        _isListening = false;
        _lessonPlan = 'Recording failed.';
        _showRetry = true;
      });
      return;
    }

    final transcript = await _transcribeAudio(File(recordedPath));
    final plan = await _generateLessonPlan(transcript);

    setState(() {
      _isListening = false;
      _lessonPlan = plan ?? 'No lesson plan returned.';
      _showRetry = plan == null || plan.contains('Invalid');
    });

    Navigator.pushNamed(
      context,
      '/lessonPlan',
      arguments: {'lessonPlan': _lessonPlan},
    );
  }

  Future<String> _transcribeAudio(File file) async {
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
            )
            ..headers['Authorization'] =
                'Bearer ${dotenv.env['OPENAI_API_KEY']}'
            ..fields['model'] = 'whisper-1'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode != 200) return 'Transcription failed';

      final res = await http.Response.fromStream(response);
      final body = jsonDecode(res.body);
      return body['text'] ?? 'No text found.';
    } catch (e) {
      print("❌ Transcription error: $e");
      return 'Transcription error.';
    }
  }

  Future<String?> _generateLessonPlan(String transcript) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a language tutor. Create a beginner-friendly lesson plan based on the user's spoken input and target language: ${widget.selectedLanguage}.",
            },
            {"role": "user", "content": transcript},
          ],
        }),
      );

      print("🔵 Raw GPT response body: ${response.body}");

      if (response.statusCode != 200) return 'GPT failed';

      final jsonBody = jsonDecode(response.body);
      final content = jsonBody['choices']?[0]?['message']?['content'];
      return content?.trim() ?? 'Invalid GPT response.';
    } catch (e) {
      print("❌ GPT response parse error: $e");
      return 'Invalid GPT response.';
    }
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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _lessonPlan,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          if (_showRetry) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startAssessmentFlow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[200],
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ],
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
