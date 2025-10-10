// lib/services/cloud_tts_service.dart
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudTtsService {
  final AudioPlayer _player = AudioPlayer();
  final String model;
  final String voice;

  CloudTtsService({this.model = 'tts-1', this.voice = 'alloy'});

  Future<void> speak(String text, {String format = 'mp3'}) async {
    final s = text.trim();
    if (s.isEmpty) return;

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      // Fail silently so UI doesn’t crash in dev if key is missing.
      return;
    }

    final uri = Uri.parse('https://api.openai.com/v1/audio/speech');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'voice': voice,
        'input': s,
        'format': format, // mp3
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('TTS error ${res.statusCode}: ${res.body}');
    }

    await _player.stop();
    await _player.play(BytesSource(res.bodyBytes));
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
  }
}
