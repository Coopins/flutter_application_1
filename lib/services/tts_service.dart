import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(String text, {String lang = 'en-US'}) async {
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(
      true,
    ); // Ensures the app waits until speaking finishes
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}
