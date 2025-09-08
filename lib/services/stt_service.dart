import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class STTService {
  STTService({required this.apiKey});
  final String apiKey;

  /// Transcribe audio with OpenAI Whisper. Returns plain text.
  Future<String> transcribe(File audioFile, {String? languageCode}) async {
    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');

    final req =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = 'whisper-1'
          ..fields['response_format'] = 'text';
    if (languageCode != null && languageCode.isNotEmpty) {
      // optional hint to Whisper (ISO 639-1 like 'es','de','fr','it','pt','zh')
      req.fields['language'] = languageCode.toLowerCase();
    }
    req.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body.trim();
    }
    debugPrint('Whisper error ${resp.statusCode}: ${resp.body}');
    throw Exception('Transcription failed (${resp.statusCode}).');
  }
}
