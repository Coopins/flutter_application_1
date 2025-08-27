import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  OpenAIService._();
  static final OpenAIService instance = OpenAIService._();

  bool _ready = false;
  late String _apiKey;
  late String _baseUrl; // cleaned
  late String _model;

  String _safeEnv(String k, {String fallback = ''}) {
    try {
      return dotenv.env[k] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // Ensure base URL is sane; if not, force the canonical endpoint.
  String _cleanBaseUrl(String raw) {
    final s = (raw).trim();
    if (s.isEmpty) return 'https://api.openai.com/v1';
    // Strip trailing slashes
    final cleaned = s.replaceAll(RegExp(r'/+$'), '');
    // Heuristic: if it doesn't mention openai.com and isn't https, force canonical
    if (!cleaned.startsWith('http') || !cleaned.contains('openai.com')) {
      return 'https://api.openai.com/v1';
    }
    return cleaned;
  }

  Uri _chatUri() => Uri.parse('$_baseUrl/chat/completions');

  void _ensureInit() {
    if (_ready) return;
    _apiKey = _safeEnv('OPENAI_API_KEY');
    _baseUrl = _cleanBaseUrl(
      _safeEnv('OPENAI_BASE_URL', fallback: 'https://api.openai.com/v1'),
    );
    _model = _safeEnv('OPENAI_MODEL', fallback: 'gpt-4o-mini');

    if (_apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY missing. Ensure .env exists, is in pubspec assets, and dotenv.load() ran.',
      );
    }
    _ready = true;
  }

  Future<String> chat(String systemPrompt, String userMessage) async {
    _ensureInit();

    final uri = _chatUri();
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.3,
    });

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    // Some proxies return HTML 404; detect and explain
    final ct = resp.headers['content-type'] ?? '';
    final isJson = ct.contains('application/json');

    if (resp.statusCode >= 200 && resp.statusCode < 300 && isJson) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          json['choices']?[0]?['message']?['content'] as String? ?? '';
      return content.trim();
    }

    if (!isJson) {
      debugPrint(
        'OpenAI non-JSON response ${resp.statusCode} at $uri\n${resp.body}',
      );
      throw Exception(
        'OpenAI endpoint returned non-JSON (${resp.statusCode}). '
        'Base URL was $_baseUrl. Check proxies/VPN and OPENAI_BASE_URL.',
      );
    }

    // JSON error from OpenAI
    debugPrint('OpenAI error ${resp.statusCode}: ${resp.body}');
    throw Exception('OpenAI request failed (${resp.statusCode})');
  }
}
