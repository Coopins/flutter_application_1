import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final http.Client _client = http.Client();

  Future<String> generateLessonPlan({
    required String selectedLanguage,
    required String performanceSummary,
  }) async {
    final prompt =
        "You are a language tutor. Come up with a lesson plan for someone learning $selectedLanguage based on the following response: $performanceSummary";

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': 'You are a language tutor.'},
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content'];
      return content;
    } else {
      throw Exception(
        'OpenAI request failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
