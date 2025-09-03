import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Tiny wrapper for TTS that is production-safe (no raw `print`).
class TTSService {
  TTSService._(); // no instances

  static final FlutterTts _tts = FlutterTts();

  /// Configure base settings for clarity and voice consistency.
  static Future<void> setDefaults() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // slightly slower for clarity
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      // On Android this helps quality; it’s a no-op elsewhere.
      try {
        await _tts.setEngine('com.google.android.tts');
      } catch (e) {
        if (kDebugMode) debugPrint('TTS setEngine warning: $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('TTS setDefaults error: $e');
    }
  }

  /// Speak a phrase in the specified language.
  static Future<void> speak(String text, {String lang = 'en-US'}) async {
    try {
      await stop(); // stop any ongoing speech first
      if (lang.isNotEmpty) await _tts.setLanguage(lang);
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) debugPrint('TTS speak error: $e');
    }
  }

  /// Stop current speech.
  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS stop error: $e');
    }
  }
}
