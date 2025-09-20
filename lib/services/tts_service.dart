// lib/services/tts_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef SpeakingListener = void Function(bool);

class TtsService {
  TtsService({
    this.defaultLocale,
    this.rate = 0.38, // << much slower baseline
    this.pitch = 1.0,
  }) {
    _tts.setStartHandler(() {
      _isSpeaking = true;
      try {
        _activeOnStart?.call();
      } catch (_) {}
      _notifySpeaking(true);
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      final onComplete = _activeOnComplete;
      _activeOnStart = null;
      _activeOnComplete = null;
      _notifySpeaking(false);
      try {
        onComplete?.call();
      } catch (_) {}
    });
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      _isSpeaking = false;
      final onComplete = _activeOnComplete;
      _activeOnStart = null;
      _activeOnComplete = null;
      _notifySpeaking(false);
      try {
        onComplete?.call();
      } catch (_) {}
    });

    // Ensure completion callbacks fire on all platforms.
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts = FlutterTts();
  final String? defaultLocale;
  double rate;
  final double pitch;

  bool _isSpeaking = false;
  VoidCallback? _activeOnStart;
  VoidCallback? _activeOnComplete;

  SpeakingListener? speakingStateListener;

  bool get isSpeaking => _isSpeaking;

  void _notifySpeaking(bool v) {
    try {
      speakingStateListener?.call(v);
    } catch (_) {}
  }

  Future<void> _setBestLanguage(String? desired) async {
    if (desired == null || desired.isEmpty) return;
    try {
      final langs =
          (await _tts.getLanguages)?.cast<String>() ?? const <String>[];

      // exact first
      if (langs.contains(desired)) {
        await _tts.setLanguage(desired);
        return;
      }

      // same family (e.g., es-*, pt-*)
      final family = desired.split('-').first;
      final sameFamily = langs.firstWhere(
        (l) => l.toLowerCase().startsWith('$family-'),
        orElse: () => '',
      );
      if (sameFamily.isNotEmpty) {
        await _tts.setLanguage(sameFamily);
        return;
      }

      // plain language code
      if (langs.contains(family)) {
        await _tts.setLanguage(family);
        return;
      }
    } catch (e) {
      debugPrint('TtsService: getLanguages/setLanguage failed: $e');
    }
  }

  /// Optionally override rate per call via [rateOverride]
  Future<void> speak(
    String text, {
    String? locale,
    double? rateOverride,
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    _activeOnStart = onStart;
    _activeOnComplete = onComplete;

    await _setBestLanguage(locale ?? defaultLocale);

    final r = (rateOverride ?? rate).clamp(0.2, 1.0);
    await _tts.setSpeechRate(r);
    await _tts.setPitch(pitch);

    await _tts.speak(text);
  }

  Future<void> stop() async {
    _activeOnStart = null;
    final onComplete = _activeOnComplete;
    _activeOnComplete = null;

    try {
      await _tts.stop();
    } catch (_) {}

    _isSpeaking = false;
    _notifySpeaking(false);
    try {
      onComplete?.call();
    } catch (_) {}
  }
}
