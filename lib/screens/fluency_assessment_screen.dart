// lib/screens/fluency_assessment_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

import '../services/gabi_service.dart';
import '../services/lesson_plan_storage.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  final String? selectedLanguage;
  const FluencyAssessmentScreen({super.key, this.selectedLanguage});

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _available = false;
  bool _listening = false;
  bool _processing = false;

  // idempotency + navigation guards
  bool _savedOnce = false;
  bool _navigated = false;

  String _language = 'Spanish';
  String _ttsLocale = 'en-US';
  String _transcript = '';
  Timer? _safetyTimeout;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndListen());
  }

  Future<void> _initAndListen() async {
    _available = await _stt.initialize(
      onStatus: (s) {
        // When STT is "done" and we have speech, process it.
        if (s == 'done' && !_processing && _transcript.trim().isNotEmpty) {
          _processTranscript();
        }
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Speech error: ${e.errorMsg}')));
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

    await _startListening();
  }

  String _localeForLanguage(String language) {
    switch (language) {
      case 'Spanish':
        return 'es_ES';
      case 'French':
        return 'fr_FR';
      case 'German':
        return 'de_DE';
      case 'Chinese':
        return 'zh_CN';
      default:
        return 'en_US';
    }
  }

  Future<void> _startListening() async {
    if (!_available || _listening) return;
    setState(() {
      _transcript = '';
      _listening = true;
      _savedOnce = false; // reset guards for a new attempt
      _navigated = false;
    });

    await _stt.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 2), // auto‑stop after 2s silence
      partialResults: true,
      localeId: _localeForLanguage(_language),
      listenMode: stt.ListenMode.confirmation,
    );

    // Safety: if STT never calls "done", stop after 16s
    _safetyTimeout?.cancel();
    _safetyTimeout = Timer(const Duration(seconds: 16), () async {
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
      _stopListening(); // triggers processing
    }
  }

  Future<void> _processTranscript() async {
    if (_processing || _savedOnce) return; // strong guard
    setState(() => _processing = true);

    try {
      final text = _transcript.trim();
      if (text.isEmpty) throw Exception('No speech detected');

      final plan = await GabiService.generateLessonPlanFromTranscript(
        transcript: text,
        language: _language,
      );

      if (_savedOnce) return; // double-check race
      final id = await LessonPlanStorage.savePlan(
        markdown: plan,
        language: _language,
      );
      _savedOnce = true;

      if (!mounted || _navigated) return;
      _navigated = true;
      HapticFeedback.lightImpact();
      // Replace current screen to avoid stacking multiple copies
      Navigator.pushReplacementNamed(
        context,
        '/lessonPlan',
        arguments: {
          'lessonId': id,
          'language': _language,
          'ttsLocale': _ttsLocale,
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
    _stt.cancel(); // end any active session
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF7C3AED);
    final statusText =
        _processing
            ? 'Generating lesson plan…'
            : _listening
            ? 'Listening… (pause to finish)'
            : 'Tap mic to start';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fluency Assessment'),
        backgroundColor: Colors.black,
        elevation: 0,
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
                          await _startListening();
                        }
                      },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color:
                      _listening
                          ? purple.withOpacity(0.25)
                          : const Color(0xFF1A1F29),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_listening)
                      BoxShadow(
                        color: purple.withOpacity(0.4),
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
