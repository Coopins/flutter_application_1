// lib/services/lesson_generator_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart' as fdotenv;

/// Generates a structured Markdown lesson plan from a transcript.
/// Uses OpenAI chat completions (default: gpt-4o-mini).
class LessonGeneratorService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _defaultModel = 'gpt-4o-mini';

  /// targetLanguage is a name like "German", "French", "Spanish", etc.
  static Future<String> generateMarkdown({
    required String transcript,
    required String targetLanguage,
    String model = _defaultModel,
  }) async {
    final apiKey = fdotenv.dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY');
    }

    final system = '''
You are Gabi, a friendly language tutor. Produce a concise, **well-structured Markdown lesson plan** based ONLY on the learner's spoken response.
- Target language: $targetLanguage
- Output must be valid Markdown with clear headings and bullet points.
- Include:
  1) **CEFR level estimate** with 1-sentence rationale.
  2) **Summary** (in English) of what the learner said.
  3) **Strengths** and **Areas to Improve** (short bullets).
  4) **Core Vocabulary** list (target-language → brief English gloss).
  5) **Grammar/Usage Feedback**: 3–5 specific notes.
  6) **Pronunciation Tips** (target-language specific).
  7) **Speaking Practice**: 2 short prompts in $targetLanguage.
  8) **Next Steps** (3 bullets).
- Keep it actionable and compact (≈250–400 words).
''';

    final user = '''
Learner transcript (language: $targetLanguage):
"""$transcript"""
''';

    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': model,
        'temperature': 0.3,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Lesson generation failed: ${res.statusCode} ${res.body}',
      );
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final content =
        (data['choices']?[0]?['message']?['content'] ?? '').toString().trim();
    if (content.isEmpty) throw Exception('Empty lesson content');
    return content;
  }
}
