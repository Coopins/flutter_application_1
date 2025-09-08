import 'dart:convert';
import 'package:http/http.dart' as http;

/// Generates a Markdown lesson plan that MUST use the user's transcript.
/// Usage:
///   final lp = LessonPlanService(apiKey: `YOUR_OPENAI_API_KEY`);
///   final md = await lp.generatePlan(transcript: text, languageCode: 'es');
class LessonPlanService {
  final String apiKey;
  final Uri _chatUrl = Uri.parse('https://api.openai.com/v1/chat/completions');

  LessonPlanService({required this.apiKey});

  Future<String> generatePlan({
    required String transcript,
    required String languageCode,
  }) async {
    final cleaned = transcript.trim();
    if (cleaned.length < 12) {
      throw Exception('Transcript too short to generate a meaningful plan.');
    }

    final lc = languageCode.trim().toLowerCase();

    final system = '''
You create concise language lesson plans strictly grounded in the user's spoken transcript.
Requirements:
- Output in **Markdown** only (no code fences).
- The target language is "${_labelFor(lc)}"; keep level consistent with the transcript (advanced stays advanced).
- Do **not** invent unrelated beginner topics (e.g., ordering food) unless the transcript explicitly mentions them.
Structure:
# Title
_Pithy one-line overview referencing the transcript's topic._
## Goals
- Two bullet goals tailored to the transcript.
## Key Phrases
- 5–7 items: Spanish phrase — brief English gloss.
## Mini-Dialogue
- 4–6 lines using the transcript’s topic and vocabulary.
## Quick Practice
- 3 prompt bullets users can answer aloud, tied to the transcript content.
''';

    final user = '''
Transcript (verbatim):
"""
$cleaned
"""

Generate the lesson fully aligned to the transcript above.
If your draft does not clearly reflect this transcript’s topic, regenerate mentally before responding.
''';

    final body = json.encode({
      'model': 'gpt-4o-mini',
      'temperature': 0.4,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'max_tokens': 900,
    });

    final resp = await http.post(
      _chatUrl,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Plan generation error ${resp.statusCode}: ${resp.body}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final content =
        (data['choices']?[0]?['message']?['content'] ?? '').toString().trim();

    if (content.isEmpty) {
      throw Exception('Empty plan content from model.');
    }
    return content;
  }

  String _labelFor(String lc) {
    switch (lc) {
      case 'es':
      case 'spanish':
        return 'Spanish';
      case 'fr':
      case 'french':
        return 'French';
      case 'pt':
      case 'portuguese':
        return 'Portuguese';
      case 'ja':
      case 'japanese':
        return 'Japanese';
      case 'ko':
      case 'korean':
        return 'Korean';
      case 'ro':
      case 'romanian':
        return 'Romanian';
      case 'ru':
      case 'russian':
        return 'Russian';
      default:
        return 'English';
    }
  }
}
