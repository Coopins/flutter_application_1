// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Minimal OpenAI wrapper for Gabi.
/// - transcribeAudio(file) -> transcript String
/// - generateLessonPlan(transcript, targetLanguage) -> Map {title, sections:[{heading,content}]}
/// - planToMarkdown(plan) -> String markdown for LessonPlanScreen
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw StateError('OPENAI_API_KEY missing from .env');
    }
    return key;
  }

  /// Transcribe audio using OpenAI Audio Transcriptions API.
  /// Default model kept as 'whisper-1' to match your current code.
  Future<String> transcribeAudio(
    File file, {
    String model = 'whisper-1',
  }) async {
    final req =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
          )
          ..headers['Authorization'] = 'Bearer $_apiKey'
          ..fields['model'] = model
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('Transcription failed (${res.statusCode}): ${res.body}');
    }

    final body = jsonDecode(res.body);
    final text = body['text']?.toString() ?? '';
    if (text.isEmpty) throw Exception('No text returned from transcription.');
    return text;
  }

  /// Generate a structured lesson plan (JSON) using Chat Completions.
  /// We request strict JSON using response_format to make parsing robust.
  Future<Map<String, dynamic>> generateLessonPlan({
    required String transcript,
    required String targetLanguage,
    String model = 'gpt-4o-mini',
    double temperature = 0.3,
  }) async {
    final body = {
      'model': model,
      'temperature': temperature,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are Gabi, a supportive language tutor. Return JSON ONLY with fields: '
              '{ "title": string, "sections": [ { "heading": string, "content": string }, ... ] }. '
              'Keep it practical, 4–6 sections, concise explanations.',
        },
        {
          'role': 'user',
          'content':
              'Target language: $targetLanguage\n'
              'Learner transcript: "$transcript"\n'
              'Create a tailored lesson plan.',
        },
      ],
      'response_format': {'type': 'json_object'},
    };

    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('OpenAI error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;
    final plan = jsonDecode(content) as Map<String, dynamic>;
    return plan;
  }

  /// Convert a plan Map to markdown for the LessonPlanScreen.
  String planToMarkdown(Map<String, dynamic> plan) {
    final title = (plan['title'] ?? 'Lesson Plan').toString();
    final sections = (plan['sections'] as List?) ?? const [];
    final b = StringBuffer()..writeln('# $title\n');
    for (final s in sections) {
      final h = (s['heading'] ?? '').toString();
      final c = (s['content'] ?? '').toString();
      if (h.isNotEmpty) b.writeln('## $h');
      if (c.isNotEmpty) b.writeln('$c\n');
    }
    return b.toString();
  }
}
