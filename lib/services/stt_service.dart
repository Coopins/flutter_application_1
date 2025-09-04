import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as fdotenv;

/// Centralized Speech-to-Text wrapper with dictation mode + locale match.
class STTService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  String _localeId = 'en-US';
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;
  String get localeId => _localeId;

  Future<void> init() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (kDebugMode) debugPrint('Mic permission not granted');
      _available = false;
      return;
    }

    _available = await _stt.initialize(
      onError: (e) =>
          kDebugMode ? debugPrint('STT error: ${e.errorMsg}') : null,
      onStatus: (s) => kDebugMode ? debugPrint('STT status: $s') : null,
    );
    if (!_available) return;

    // Pick locale from env SPEECH_LOCALE (e.g., en-US, es-ES) with graceful fallback.
    final desired = fdotenv.dotenv.maybeGet('SPEECH_LOCALE') ?? 'en-US';
    final locales = await _stt.locales();
    final match = locales.firstWhere(
      (l) => l.localeId.toLowerCase() == desired.toLowerCase(),
      orElse: () {
        final lang = desired.split('-').first.toLowerCase();
        return locales.firstWhere(
          (l) => l.localeId.toLowerCase().startsWith(lang),
          orElse: () => locales.first,
        );
      },
    );
    _localeId = match.localeId;
  }

  Future<void> start({
    required void Function(String text) onText,
    Duration listenFor = const Duration(seconds: 20),
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    if (!_available) return;

    String buffer = '';
    await _stt.listen(
      localeId: _localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      // Use the modern API to avoid deprecation warnings.
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        onDevice: false,
      ),
      onResult: (res) {
        buffer = res.recognizedWords;
        onText(buffer);
      },
    );
  }

  Future<void> stop() async {
    if (!_available) return;
    await _stt.stop();
  }

  Future<void> cancel() async {
    if (!_available) return;
    await _stt.cancel();
  }
}
