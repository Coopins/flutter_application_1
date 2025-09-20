// lib/services/category_chat_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'stt_service.dart';
import 'transcription_service.dart';
import 'tts_service.dart';

/// Turn-taking category chat service for Gabi.
/// - STT: Whisper via TranscriptionService (auto-detect language by default)
/// - TTS: FlutterTTS via TtsService (slow, locale-aware)
/// - Auto-resumes listening after each reply unless user pressed Stop.
class CategoryChatService {
  CategoryChatService({
    required this.categoryId,
    required this.categoryTitle,
    required this.languageLabel,
    required this.systemPromptForCategory,
    required this.ttsService,
    required this.sttService,
    this.ttsLocale,
    this.onSpeakingChanged,
    this.transcribeLanguageHint, // optional: e.g., 'es' – null => auto-detect
  }) {
    ttsService.speakingStateListener = (v) => onSpeakingChanged?.call(v);
  }

  // --- Context ---
  final String categoryId;
  final String categoryTitle;
  final String languageLabel; // e.g., "Spanish"
  final String systemPromptForCategory;

  // --- IO services ---
  final TtsService ttsService;
  final SttService sttService;

  // --- Options / hooks ---
  final String? ttsLocale; // e.g., 'es-ES'
  final void Function(bool)? onSpeakingChanged;

  /// If you *really* want to hint Whisper (e.g., 'es'), set this.
  /// Leaving null lets Whisper auto-detect (recommended for code-switching).
  final String? transcribeLanguageHint;

  // --- State ---
  bool _autoListenEnabled = true; // Mic press re-enables this loop.
  bool get isSpeaking => ttsService.isSpeaking;

  /// Gabi opens with a short intro and then begins listening (unless user hits Stop).
  Future<void> speakIntro() async {
    final intro =
        'Category: $categoryTitle. Tap the mic to speak, then tap send when you are finished. I will reply in $languageLabel.';
    await ttsService.speak(
      intro,
      locale: ttsLocale,
      rateOverride: 0.37, // even slower intro
      onComplete: () async {
        if (_autoListenEnabled) {
          await startListening();
        }
      },
    );
  }

  /// Start microphone capture. Also (re)enables auto-listen loop.
  Future<void> startListening() async {
    if (await sttService.isRecording) return;
    _autoListenEnabled = true;
    await sttService.start();
  }

  /// Hard stop: cancels recording *and* disables auto-listen.
  Future<void> stopListening() async {
    _autoListenEnabled = false;
    await sttService.stop(); // ignore null
  }

  /// If Gabi is speaking, stop TTS and immediately start listening.
  Future<void> bargeIn() async {
    if (ttsService.isSpeaking) {
      await ttsService.stop();
    }
    await startListening();
  }

  /// Stop recording, transcribe, send to Chat Completions, speak reply.
  /// Applies guards against junk/short transcripts and resumes listening if enabled.
  Future<CategoryTurnResult> stopAndProcess() async {
    try {
      final path = await sttService.stop();
      if (path == null || path.isEmpty) {
        return CategoryTurnResult.empty();
      }

      // Let Whisper auto-detect by default to avoid garbage when user speaks English.
      final raw = await TranscriptionService.transcribeFile(
        file: File(path),
        language: transcribeLanguageHint, // null -> auto-detect
      );

      // ---- Junk/short guard ----
      final t = raw.trim();
      final lower = t.toLowerCase();
      const junkSingles = {'bell', 'silence', 'noise', 'um', 'uh'};
      final isJunk =
          t.isEmpty ||
          t.length < 3 ||
          (t.split(RegExp(r'\s+')).length <= 2 && junkSingles.contains(lower));
      if (isJunk) {
        if (_autoListenEnabled) await startListening();
        return CategoryTurnResult.empty();
      }
      // --------------------------

      final assistant = await _chatCompletion(
        system: systemPromptForCategory,
        user: t,
      );

      await ttsService.speak(
        assistant,
        locale: ttsLocale,
        rateOverride: 0.34, // slow replies
        onComplete: () async {
          if (_autoListenEnabled) {
            await startListening();
          }
        },
      );

      return CategoryTurnResult(userText: t, assistantText: assistant);
    } catch (e, st) {
      debugPrint('CategoryChatService.stopAndProcess error: $e\n$st');
      rethrow;
    }
  }

  // --- OpenAI Chat Completions (dotenv OPENAI_API_KEY) ---
  Future<String> _chatCompletion({
    required String system,
    required String user,
    String model = 'gpt-4o-mini',
    double temperature = 0.7,
    int maxTokens = 300,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY is missing. Add it to env/.env and restart the app.',
      );
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final List choices = (data['choices'] as List? ?? const []);
      if (choices.isEmpty) return '';
      final msg = choices.first['message'] as Map<String, dynamic>?;
      final content = (msg?['content'] ?? '').toString();
      return content.trim();
    }

    throw Exception('OpenAI chat failed ${resp.statusCode}: ${resp.body}');
  }
}

class CategoryTurnResult {
  final String? userText;
  final String? assistantText;
  const CategoryTurnResult({this.userText, this.assistantText});
  factory CategoryTurnResult.empty() =>
      const CategoryTurnResult(userText: null, assistantText: null);
}
