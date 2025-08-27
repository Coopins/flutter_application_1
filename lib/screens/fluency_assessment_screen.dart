import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:flutter_application_1/services/gabi_service.dart';
import 'package:flutter_application_1/services/lesson_plan_storage.dart';
import 'package:flutter_application_1/routes.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  final String? selectedLanguage;
  const FluencyAssessmentScreen({super.key, this.selectedLanguage});

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _available = false;
  bool _listening = false;
  bool _processing = false;

  bool _savedOnce = false;
  bool _navigated = false;

  String _language = 'Spanish';
  String _ttsLocale = 'en-US';
  String _transcript = '';
  Timer? _safetyTimeout;

  stt.LocaleName? _chosenLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _language =
        args['selectedLanguage'] as String? ??
        widget.selectedLanguage ??
        _language;
    _ttsLocale = args['ttsLocale'] as String? ?? _ttsLocale;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _introThenListen());
  }

  String _langPrefix(String language) {
    switch (language) {
      case 'Spanish':
        return 'es';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      case 'Chinese':
        return 'zh';
      default:
        return 'en';
    }
  }

  String _questionFor(String language) {
    switch (language) {
      case 'Spanish':
        return '¿Qué hiciste el fin de semana pasado?';
      case 'French':
        return 'Qu’as-tu fait le week-end dernier ?';
      case 'German':
        return 'Was hast du letztes Wochenende gemacht?';
      case 'Chinese':
        return '你上个周末做了什么？';
      default:
        return 'What did you do last weekend?';
    }
  }

  Future<void> _introThenListen() async {
    try {
      await _tts.setLanguage(_ttsLocale);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      final intro =
          "Hi! I’m going to assess your fluency in $_language. Please answer the following in $_language.";
      final question = _questionFor(_language);

      await _tts.awaitSpeakCompletion(true);
      await _tts.stop();
      await _tts.speak("$intro $question");
      await Future.delayed(const Duration(milliseconds: 250));
      await _initAndStartListening();
    } catch (_) {
      await _initAndStartListening();
    }
  }

  Future<void> _initAndStartListening() async {
    _available = await _stt.initialize(
      onStatus: (s) {
        if (s == 'done' && !_processing && _transcript.trim().isNotEmpty) {
          _processTranscript();
        }
      },
      onError: (e) {
        if (!mounted) return;
        final msg =
            e.errorMsg == 'error_no_match'
                ? 'Didn’t catch that. Try again, a bit closer to the mic.'
                : 'Speech error: ${e.errorMsg}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _listening = false);
      },
    );

    if (!_available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device.'),
        ),
      );
      return;
    }

    final locales = await _stt.locales();
    final system = await _stt.systemLocale();
    final p = _langPrefix(_language).toLowerCase();

    stt.LocaleName? pick;
    for (final l in locales) {
      final id = l.localeId.toLowerCase();
      if (id.startsWith('${p}_') || id.startsWith('${p}-') || id == p) {
        pick = l;
        break;
      }
    }
    _chosenLocale = pick ?? system;

    await Future.delayed(const Duration(milliseconds: 150));
    await _startListeningLong();
  }

  Future<void> _startListeningLong() async {
    if (!_available || _listening) return;
    setState(() {
      _transcript = '';
      _listening = true;
      _savedOnce = false;
      _navigated = false;
    });

    await _stt.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 5),
      localeId: _chosenLocale?.localeId,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    _safetyTimeout?.cancel();
    _safetyTimeout = Timer(const Duration(minutes: 1, seconds: 5), () async {
      if (_listening) await _stopListening();
    });
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    _safetyTimeout?.cancel();
    await _stt.stop();
    if (!mounted) return;
    setState(() => _listening = false);

    if (_transcript.trim().isNotEmpty && !_processing) {
      _processTranscript();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _transcript = result.recognizedWords);
    if (result.finalResult) {
      _stopListening();
    }
  }

  Future<void> _processTranscript() async {
    if (_processing || _savedOnce) return;
    setState(() => _processing = true);

    try {
      final text = _transcript.trim();
      if (text.isEmpty) throw Exception('No speech detected');

      final planMd = await GabiService.generateLessonPlanFromTranscript(
        transcript: text,
        language: _language,
      );

      final id = await LessonPlanStorage.savePlan(
        markdown: planMd,
        language: _language,
      );
      _savedOnce = true;

      if (!mounted || _navigated) return;
      _navigated = true;
      HapticFeedback.lightImpact();
      Navigator.pushReplacementNamed(
        context,
        Routes.lessonPlan,
        arguments: {
          'lessonId': id,
          'language': _language,
          'ttsLocale': _ttsLocale,
          'initialMarkdown': planMd,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create lesson plan: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  void dispose() {
    _safetyTimeout?.cancel();
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF7C3AED);
    final statusText =
        _processing
            ? 'Generating lesson plan…'
            : _listening
            ? 'Listening… tap mic to stop'
            : 'Tap mic to start';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fluency Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed:
                () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (r) => false,
                ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_language, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap:
                  _processing
                      ? null
                      : () async {
                        if (_listening) {
                          await _stopListening();
                        } else {
                          await _startListeningLong();
                        }
                      },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color:
                      _listening
                          ? purple.withValues(alpha: 0.25)
                          : const Color(0xFF1A1F29),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_listening)
                      BoxShadow(
                        color: purple.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (_transcript.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _transcript,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
            if (_processing) ...[
              const SizedBox(height: 14),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
