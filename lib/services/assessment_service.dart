// lib/services/assessment_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Service for recording, transcribing, generating, and saving lesson plans.
/// Use it from your FluencyAssessmentScreen (the UI one we wired earlier).
class AssessmentService {
  AssessmentService._();
  static final AssessmentService instance = AssessmentService._();

  final AudioRecorder _recorder = AudioRecorder();

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? ''; // required
  String get _baseUrl =>
      dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  String get _chatModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';
  String get _sttModel => dotenv.env['OPENAI_TRANSCRIBE_MODEL'] ?? 'whisper-1';

  Map<String, String> get _authJsonHeaders => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  void _ensureKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing. Create a .env file, add the key, '
        'add ".env" to pubspec assets, and load it in main() with dotenv.',
      );
    }
  }

  /// High-level: record for [duration], transcribe, generate markdown plan.
  /// Returns the markdown lesson plan.
  Future<String> recordTranscribeAndGeneratePlan({
    required String language,
    Duration duration = const Duration(seconds: 10),
  }) async {
    _ensureKey();

    // Request mic permission
    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      throw StateError('Microphone permission denied');
    }

    // Record to temp WAV
    final wav = await _recordToTempWav(duration);

    try {
      // Transcribe
      final transcript = await transcribe(wav);

      // Generate plan
      final plan = await generateLessonPlan(
        transcript: transcript,
        language: language,
      );

      return plan;
    } finally {
      // cleanup temp file
      if (wav.existsSync()) {
        try {
          await wav.delete();
        } catch (_) {}
      }
    }
  }

  /// Records audio to a temporary 16k WAV file for [duration].
  Future<File> _recordToTempWav(Duration duration) async {
    final tmpDir = await getTemporaryDirectory();
    final filePath = p.join(
      tmpDir.path,
      'gabgo_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    final cfg = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 128000,
    );

    await _recorder.start(cfg, path: filePath);
    await Future.delayed(duration);

    final recordedPath = await _recorder.stop();
    if (recordedPath == null) {
      throw StateError('Recording failed (no path)');
    }

    final wav = File(recordedPath);
    if (!wav.existsSync()) {
      throw StateError('Recording failed (file missing)');
    }
    return wav;
  }

  /// Transcribes a WAV file using OpenAI Whisper.
  Future<String> transcribe(File file) async {
    _ensureKey();

    final uri = Uri.parse('$_baseUrl/audio/transcriptions');
    final req =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $_apiKey'
          ..fields['model'] = _sttModel
          ..fields['response_format'] = 'json'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('Transcription error ${resp.statusCode}: ${resp.body}');
      throw Exception('Transcription failed (${resp.statusCode})');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (json['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw Exception('Transcription returned empty text');
    }
    return text;
  }

  /// Generates a markdown lesson plan from [transcript] and [language].
  Future<String> generateLessonPlan({
    required String transcript,
    required String language,
  }) async {
    _ensureKey();

    final systemPrompt = '''
You are Gabi, a concise language coach. Create a short, actionable LESSON PLAN in Markdown
based on the user's spoken transcript and target language. Use this structure:

# Lesson Plan: <Language>
## Objectives
- 3–5 bullets
## Vocabulary
- word — short gloss
## Drills
1) ...
2) ...
## Practice Prompt
One short prompt in the target language.

Keep it under ~250–400 words. Do not use code fences.
''';

    final userMsg = '''
Language: $language
Learner response (raw transcript):
"$transcript"
''';

    final uri = Uri.parse('$_baseUrl/chat/completions');
    final body = jsonEncode({
      'model': _chatModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMsg},
      ],
      'temperature': 0.3,
    });

    final resp = await http.post(uri, headers: _authJsonHeaders, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('OpenAI error ${resp.statusCode}: ${resp.body}');
      // Return a fallback so the UX continues
      return _fallbackPlan(language);
    }

    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          json['choices']?[0]?['message']?['content'] as String? ?? '';
      if (content.trim().isEmpty) return _fallbackPlan(language);
      return content.trim();
    } catch (e) {
      debugPrint('OpenAI parse error: $e');
      return _fallbackPlan(language);
    }
  }

  /// Saves the lesson plan to Firestore and returns the document id.
  Future<String> savePlan({
    required String markdown,
    required String language,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not signed in');
    }
    final col = FirebaseFirestore.instance
        .collection('lessonPlans')
        .doc(user.uid)
        .collection('items');

    final doc = await col.add({
      'markdown': markdown,
      'language': language,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  String _fallbackPlan(String language) => '''
# Lesson Plan: $language Basics
## Objectives
- Share what you did last weekend
- Use past-tense time markers
- Practice 6 core verbs

## Vocabulary
- fin de semana — weekend
- hice — I did
- fui — I went
- comí — I ate
- vi — I saw
- con — with

## Drills
1) Repeat: "El fin de semana pasado, yo ___".
2) Fill in verbs: hice / fui / comí / vi.
3) Describe 2 activities you did.

## Practice Prompt
En $language, describe lo que hiciste el fin de semana pasado en 3–4 frases.
''';
}
