// lib/services/transcription_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

/// Whisper transcription via OpenAI with resilient timeouts and clear errors.
class TranscriptionService {
  static final Uri _endpoint = Uri.parse(
    'https://api.openai.com/v1/audio/transcriptions',
  );

  /// Transcribe an audio [file] using OpenAI Whisper.
  ///
  /// - [language] should be ISO-639-1 (es, fr, de, it, pt, en, …) or null for auto.
  /// - [timeout] applies to the entire HTTP round-trip.
  static Future<String> transcribeFile({
    required File file,
    String? language,
    Duration timeout = const Duration(seconds: 65),
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY (set it in env/.env).');
    }
    if (!file.existsSync()) {
      throw Exception('Audio file not found.');
    }

    final req =
        http.MultipartRequest('POST', _endpoint)
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = 'whisper-1';

    if (language != null && language.isNotEmpty) {
      req.fields['language'] = language; // ISO-639-1
    }

    req.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: p.basename(file.path),
        contentType: MediaType('audio', _inferSubtype(file.path)),
      ),
    );

    final client = http.Client();
    try {
      final streamed = await client.send(req).timeout(timeout);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return (body['text'] ?? '').toString();
      }

      throw Exception(
        'Transcription failed (${resp.statusCode}): ${resp.body}',
      );
    } on TimeoutException {
      throw Exception('Transcription timed out. Please try again.');
    } finally {
      client.close();
    }
  }

  static String _inferSubtype(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.wav')) return 'wav';
    if (lower.endsWith('.m4a')) return 'm4a';
    if (lower.endsWith('.mp4')) return 'mp4';
    if (lower.endsWith('.aac')) return 'aac';
    if (lower.endsWith('.webm')) return 'webm';
    return 'mpeg';
  }
}
