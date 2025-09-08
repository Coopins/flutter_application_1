// lib/services/tts_service.dart
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Safer TTS wrapper with slower defaults and robust completion.
class TTSService {
  final FlutterTts _tts = FlutterTts();
  Completer<void>? _speakC;

  Future<void> configure({
    String? language,
    double rate = 0.45, // slower by default
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    if (language != null) await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(volume);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speakBlocking(
    String text, {
    String? desiredLocale,
    double? rate,
    double? pitch,
    double? volume,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (desiredLocale != null) await _tts.setLanguage(desiredLocale);
    if (rate != null) await _tts.setSpeechRate(rate);
    if (pitch != null) await _tts.setPitch(pitch);
    if (volume != null) await _tts.setVolume(volume);

    // Fresh completer & handlers each call
    final c = Completer<void>();
    _speakC = c;

    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {
      if (!c.isCompleted) c.complete();
    });
    _tts.setCancelHandler(() {
      if (!c.isCompleted) c.complete();
    });
    _tts.setErrorHandler((msg) {
      if (!c.isCompleted) c.complete();
    });

    // Ensure a clean buffer before speaking (safe on Android & iOS)
    await _tts.stop();
    await _tts.speak(text);

    try {
      await c.future.timeout(timeout);
    } catch (_) {
      // If it times out, force stop to prevent lock
      await _tts.stop();
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    final c = _speakC;
    if (c != null && !c.isCompleted) c.complete();
  }

  void dispose() {
    _tts.stop();
  }
}
