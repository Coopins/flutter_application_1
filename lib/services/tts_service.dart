import 'package:flutter_tts/flutter_tts.dart';

/// Singleton-style TTS with simple static helpers to match the screen’s usage.
class TTSService {
  TTSService._();
  static final FlutterTts _tts = FlutterTts();
  static bool _inited = false;

  static Future<void> _ensureInit() async {
    if (_inited) return;
    // These are safe cross-platform defaults; adjust as you like.
    await _tts.awaitSpeakCompletion(true); // helps ordering speak/stop
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _inited = true;
  }

  /// Set base defaults (optionally override). Keeps the static API your screen expects.
  static Future<void> setDefaults({
    String? lang, // e.g., 'en-US' or 'es-ES'
    double pitch = 1.0,
    double rate = 0.45,
    double volume = 1.0,
  }) async {
    await _ensureInit();
    if (lang != null && lang.isNotEmpty) {
      await _tts.setLanguage(lang);
    }
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(volume);
  }

  /// Speak some text. If [lang] provided, switch temporarily to that voice/language.
  static Future<void> speak(String text, {String? lang}) async {
    await _ensureInit();
    if (text.trim().isEmpty) return;

    if (lang != null && lang.isNotEmpty) {
      await _tts.setLanguage(lang);
    }
    // Stop anything currently queued to avoid overlapping audio.
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _ensureInit();
    await _tts.stop();
  }

  static Future<void> pause() async {
    await _ensureInit();
    await _tts.pause();
  }

  static Future<void> dispose() async {
    // flutter_tts has no explicit dispose; stop is enough.
    if (_inited) {
      await _tts.stop();
    }
  }
}
