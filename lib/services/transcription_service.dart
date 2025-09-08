import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

/// Whisper transcription via OpenAI.
class TranscriptionService {
  static final Uri _endpoint = Uri.parse(
    'https://api.openai.com/v1/audio/transcriptions',
  );

  /// Transcribe an audio [file] using OpenAI Whisper.
  /// If [language] is provided (ISO-639-1: es, fr, de, it, pt, en), accuracy improves.
  static Future<String> transcribeFile({
    required File file,
    String? language,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY is missing. Add it to env/.env and restart the app.',
      );
    }

    final req =
        http.MultipartRequest('POST', _endpoint)
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = 'whisper-1';

    if (language != null && language.isNotEmpty) {
      req.fields['language'] = language;
    }

    req.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: p.basename(file.path),
        contentType: MediaType('audio', _inferSubtype(file.path)),
      ),
    );

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return (body['text'] ?? '').toString();
    }

    throw Exception('Transcription failed (${resp.statusCode}): ${resp.body}');
  }

  static String _inferSubtype(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a')) return 'm4a';
    if (lower.endsWith('.mp4')) return 'mp4';
    if (lower.endsWith('.aac')) return 'aac';
    if (lower.endsWith('.wav')) return 'wav';
    if (lower.endsWith('.webm')) return 'webm';
    return 'mpeg';
  }
}
