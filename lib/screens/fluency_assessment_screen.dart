import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/tts_service.dart';

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
  Timer? _silenceTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _hasStartedRecording = false;
  bool _hasNavigated = false; // Prevents multiple pushes

  final Map<String, Map<String, String>> _languagePrompts = {
    'Spanish': {
      'question': '¿Puedes hablarme un poco sobre ti?',
      'langCode': 'es-ES',
    },
    'French': {
      'question': 'Peux-tu me parler un peu de toi ?',
      'langCode': 'fr-FR',
    },
    'German': {
      'question': 'Kannst du mir ein bisschen über dich erzählen?',
      'langCode': 'de-DE',
    },
    'Chinese': {'question': '你可以介绍一下你自己吗？', 'langCode': 'zh-CN'},
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIntroAndAssessment();
    });
  }

  Future<void> _startIntroAndAssessment() async {
    setState(() {
      _isListening = true;
      _lessonPlan = '';
      _showRetry = false;
      _hasNavigated = false;
    });

    final lang = widget.selectedLanguage;
    final prompt = _languagePrompts[lang];

    if (prompt != null) {
      final intro =
          "We’re going to assess your fluency in $lang. Please answer the next question in $lang.";

      await TTSService.stop();
      await TTSService.setDefaults();
      await TTSService.flutterTts.awaitSpeakCompletion(true); // 🔊 Sync audio

      await TTSService.speak(intro, lang: 'en-US');
      await TTSService.speak(prompt['question']!, lang: prompt['langCode']!);
    }

    await _startListeningWithSilenceDetection();
  }

  Future<void> _startListeningWithSilenceDetection() async {
    final dir = await getTemporaryDirectory();
    final filePath = path.join(
      dir.path,
      'response_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
      path: filePath,
    );

    _hasStartedRecording = true;

    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) async {
          if (amp.current > -45) {
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 2), () async {
              if (!_hasStartedRecording) return;

              _hasStartedRecording = false;
              final recordedPath = await _recorder.stop();
              _amplitudeSub?.cancel();
              if (recordedPath != null) {
                await _processRecording(File(recordedPath));
              } else {
                setState(() {
                  _isListening = false;
                  _lessonPlan = 'Recording failed.';
                  _showRetry = true;
                });
              }
            });
          }
        });
  }

  Future<void> _processRecording(File file) async {
    final transcript = await _transcribeAudio(file);
    final plan = await _generateLessonPlan(transcript);

    setState(() {
      _isListening = false;
      _lessonPlan = plan ?? 'No lesson plan returned.';
      _showRetry = plan == null || plan.contains('Invalid');
    });

    if (plan != null && !plan.contains('Invalid')) {
      final plainTextPlan = plan.replaceAll(RegExp(r'[\#\*\_\`]'), '');
      await TTSService.speak(plainTextPlan, lang: 'en-US');
    }

    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      Navigator.pushNamed(
        context,
        '/lessonPlan',
        arguments: {'lessonPlan': _lessonPlan},
      );
    }
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
                  "You are a language tutor. Assess the user's fluency level based on their spoken input in the target language: ${widget.selectedLanguage}. Then generate a personalized lesson plan that matches their level and helps them improve. The plan should include vocabulary, phrases, and examples in the target language to help the user begin practicing immediately.",
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
      children: [
        GestureDetector(
          onTap: () async {
            if (_hasStartedRecording) {
              _hasStartedRecording = false;
              final recordedPath = await _recorder.stop();
              _amplitudeSub?.cancel();
              if (recordedPath != null) {
                await _processRecording(File(recordedPath));
              }
            }
          },
          child: const Column(
            children: [
              Icon(Icons.mic, size: 80, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Gabi is listening...",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _lessonPlan,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            if (_showRetry) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startIntroAndAssessment,
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
      ),
    );
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _silenceTimer?.cancel();
    TTSService.stop();
    super.dispose();
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
