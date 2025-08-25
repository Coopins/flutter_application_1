import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GabiService {
  static String? _env(String k) => dotenv.env[k];

  /// 1) Transcribe audio
  static Future<String> transcribeAudio(
    String filePath, {
    String? languageHint,
  }) async {
    // If you have your own backend, set GABI_API_BASE_URL and use it.
    final base = _env('GABI_API_BASE_URL');
    if (base != null && base.isNotEmpty) {
      final uri = Uri.parse('$base/transcribe');
      final req = http.MultipartRequest('POST', uri);
      req.files.add(await http.MultipartFile.fromPath('file', filePath));
      if (languageHint != null) req.fields['language'] = languageHint;
      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (json['text'] as String?) ?? '';
      }
      throw Exception('Transcription failed (${res.statusCode})');
    }

    // Direct OpenAI fallback (mobile apps should ideally proxy this!)
    final apiKey = _env('OPENAI_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY');
    }
    final model = _env('OPENAI_TRANSCRIBE_MODEL') ?? 'whisper-1';
    final uri = Uri.parse(
      (_env('OPENAI_BASE_URL') ?? 'https://api.openai.com') +
          '/v1/audio/transcriptions',
    );

    final req =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = model;

    if (languageHint != null) {
      // Whisper accepts 'language' (ISO-639-1 like 'fr')
      final hint = _languageIso(languageHint);
      if (hint != null) req.fields['language'] = hint;
    }

    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await http.Response.fromStream(await req.send());

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return (json['text'] as String?) ?? '';
    }
    throw Exception('Transcription failed (${res.statusCode}) ${res.body}');
  }

  /// 2) Generate lesson plan from transcript
  static Future<String> generateLessonPlanFromTranscript({
    required String transcript,
    required String language,
  }) async {
    final base = _env('GABI_API_BASE_URL');
    if (base != null && base.isNotEmpty) {
      final uri = Uri.parse('$base/lessonplan');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transcript': transcript, 'language': language}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (json['markdown'] as String?) ?? '';
      }
      throw Exception('Lesson plan failed (${res.statusCode})');
    }

    final apiKey = _env('OPENAI_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY');
    }
    final model = _env('OPENAI_CHAT_MODEL') ?? 'gpt-4o-mini';
    final uri = Uri.parse(
      (_env('OPENAI_BASE_URL') ?? 'https://api.openai.com') +
          '/v1/chat/completions',
    );

    final prompt = '''
You are Gabi, a language tutor. The learner spoke in a fluency assessment.
Create a concise **markdown** lesson plan in $language based on the transcript.
Focus on: level guess, vocabulary, grammar notes, 10-minute practice steps, and a short quiz.
Keep it beginner-friendly if the transcript is basic. Use headings and bullet points.
Transcript:
$transcript
''';

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You create clear, structured lesson plans in markdown.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final content =
          (json['choices'] as List).first['message']['content'] as String;
      return content.trim();
    }
    throw Exception('Lesson plan failed (${res.statusCode}) ${res.body}');
  }

  static String? _languageIso(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return 'es';
      case 'french':
        return 'fr';
      case 'german':
        return 'de';
      case 'chinese':
        return 'zh';
      default:
        return null;
    }
  }
}
