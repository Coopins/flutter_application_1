import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> generateLessonPlan({
    required String selectedLanguage,
    required String performanceSummary,
  }) async {
    final prompt = '''
You are a language tutor. Come up with a lesson plan based on the user's performance.

Language: $selectedLanguage
Performance Summary: $performanceSummary
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful language tutor.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final rawContent = responseData['choices'][0]['message']['content'];

      // ✅ Properly decode any weird characters
      final decodedContent = utf8.decode(rawContent.runes.toList());

      return decodedContent;
    } else {
      throw Exception(
        'OpenAI request failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
