import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Sends a request to GPT-4o to generate a lesson plan based on language and performance.
  Future<String> generateLessonPlan({
    required String selectedLanguage,
    required String performanceSummary,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is not set in the .env file.');
    }

    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-4o",
      "messages": [
        {
          "role": "system",
          "content":
              "You are a language tutor. Come up with a lesson plan based on the user's performance.",
        },
        {
          "role": "user",
          "content":
              "The student has selected $selectedLanguage. Their current performance: $performanceSummary",
        },
      ],
      "temperature": 0.7,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = data['choices'][0]['message']['content'];
      return message.trim();
    } else {
      throw Exception(
        'OpenAI request failed: ${response.statusCode} ${response.reasonPhrase}\n${response.body}',
      );
    }
  }
}
