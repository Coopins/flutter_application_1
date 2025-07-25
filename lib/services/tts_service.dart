import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts flutterTts = FlutterTts();

  /// Configure base settings for clarity and voice consistency
  static Future<void> setDefaults() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.45); // Slightly slower for clarity
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.awaitSpeakCompletion(true); // 🔊 Ensures sequential speech

    // Optional: Enforce Google TTS on Android for better quality
    await flutterTts.setEngine("com.google.android.tts");
  }

  /// Speak a phrase in the specified language
  static Future<void> speak(String text, {String lang = 'en-US'}) async {
    try {
      await stop(); // Always stop any ongoing speech first
      await flutterTts.setLanguage(lang);
      await flutterTts.speak(text);
    } catch (e) {
      print("❌ TTS error while speaking: $e");
    }
  }

  /// Stop current speech
  static Future<void> stop() async {
    try {
      await flutterTts.stop();
    } catch (e) {
      print("⚠️ Error stopping TTS: $e");
    }
  }
}
