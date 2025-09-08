import 'dart:convert';
import 'package:http/http.dart' as http;

class LessonPlanService {
  LessonPlanService({required this.apiKey});
  final String apiKey;

  Future<String> generatePlan({
    required String transcript,
    required String languageCode, // 'es','de','fr','it','pt','zh','en'
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final system = '''
You are Gabi, a friendly language coach. Produce a SHORT, PRACTICAL, BEGINNER-FRIENDLY lesson plan in MARKDOWN only.
Audience: adult beginner practicing real-life tasks (ordering food, asking directions).
Output rules:
- Use clear headings and bullets.
- Include "Goals", "Key Phrases" (with EN translation), "Mini-Dialogue", "Pronunciation Tips", "Grammar Bite", "Drills", "Comprehension Checks", "Homework".
- Keep total length ~200–300 words.
- Use the target language for examples/phrases, include English glosses in parentheses.
- Do NOT include extra explanations outside the plan.
''';

    final user = '''
Target language code: $languageCode
Learner response (raw transcript):
$transcript
Create the lesson plan now in Markdown only.
''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.4,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });

    final resp = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Plan generation failed (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final content =
        (data['choices'] as List).first['message']['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('Empty plan content from model.');
    }
    return content.trim();
  }
}
