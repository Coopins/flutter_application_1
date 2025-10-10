// lib/screens/fluency_assessment_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../routes.dart';
import '../services/stt_service.dart';
import '../services/transcription_service.dart';
import '../services/lesson_plan_service.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  final String targetLanguage;

  const FluencyAssessmentScreen({super.key, this.targetLanguage = 'en'});

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  final FlutterTts _tts = FlutterTts();
  final SttService _stt = SttService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _status = 'Preparing…';
  String? _recordingPath;

  Timer? _hardStopTimer;
  static const int _maxRecordSeconds = 90;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runIntroThenListen());
  }

  @override
  void dispose() {
    _hardStopTimer?.cancel();
    _tts.stop();
    _stt.dispose();
    super.dispose();
  }

  Future<void> _runIntroThenListen() async {
    try {
      setState(() => _status = 'Getting ready…');

      await _tts.awaitSpeakCompletion(true);

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.38);
      await _tts.setPitch(1.0);
      await _tts.speak("Let's get started. I’ll ask you a quick question.");

      final ttsLocale = _localeFor(widget.targetLanguage);
      final question = _starterQuestion(widget.targetLanguage);
      await _tts.setLanguage(ttsLocale);
      await _tts.setSpeechRate(0.36);
      await _tts.speak(question);

      await Future.delayed(const Duration(milliseconds: 250));

      await _startRecording();
      setState(() => _status = 'Listening… Tap the mic to stop.');
    } catch (e) {
      setState(() => _status = 'TTS/init failed: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      await _stt.start();
      final actuallyRecording = await _stt.isRecording;
      if (!actuallyRecording) {
        setState(() => _status = 'Recorder did not start. Try again.');
        return;
      }

      setState(() => _isRecording = true);

      _hardStopTimer?.cancel();
      _hardStopTimer = Timer(const Duration(seconds: _maxRecordSeconds), () {
        if (_isRecording) {
          _stopRecording();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording stopped at 90s limit.')),
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _status = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      _hardStopTimer?.cancel();

      final stoppedPath = await _stt.stop();
      _isRecording = false;
      _recordingPath =
          (stoppedPath != null && stoppedPath.isNotEmpty) ? stoppedPath : null;

      if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
        setState(() => _status = 'No audio captured.');
        return;
      }
      final bytes = await File(_recordingPath!).length();
      if (bytes < 6000) {
        setState(() => _status = 'Very short recording. Please try again.');
        return;
      }

      setState(() => _status = 'Generating your lesson plan…');
      await _processRecording(_recordingPath!);
    } catch (e) {
      setState(() => _status = 'Failed to stop recording: $e');
    }
  }

  Future<void> _processRecording(String path) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final apiKey = dotenv.env['OPENAI_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Missing OPENAI_API_KEY');
      }

      // 1) Transcribe
      final transcript = await TranscriptionService.transcribeFile(
        file: File(path),
        language: widget.targetLanguage.isEmpty ? null : widget.targetLanguage,
      );

      final cleaned = transcript.trim();
      debugPrint(
        '🎧 TRANSCRIPT (${cleaned.length} chars): ${cleaned.substring(0, cleaned.length.clamp(0, 160))}',
      );
      if (cleaned.length < 12) {
        setState(
          () => _status = 'I didn’t catch enough speech. Please try again.',
        );
        return;
      }

      // 2) Generate lesson plan
      final lp = LessonPlanService(apiKey: apiKey); // ✅ fixed
      final planMarkdown = await lp.generatePlan(
        transcript: cleaned,
        languageCode: widget.targetLanguage,
      );

      // 3) Save
      String? docId;
      try {
        docId = await _saveLessonPlan(
          planMarkdown,
          language: widget.targetLanguage,
          ttsLocale: _localeFor(widget.targetLanguage),
          transcript: cleaned,
        );
      } catch (e) {
        debugPrint('⚠️ Save failed (non-blocking): $e');
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(Routes.lessonPlan, arguments: {'docId': docId});

      setState(() => _status = 'Plan generated and saved.');
    } catch (e) {
      setState(() => _status = 'Processing failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String?> _saveLessonPlan(
    String markdown, {
    required String language,
    required String ttsLocale,
    String? transcript,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'language': language,
      'markdown': markdown,
      'ttsLocale': ttsLocale,
      'createdAt': now,
      'updatedAt': now,
      if (transcript != null && transcript.isNotEmpty) 'transcript': transcript,
      'source': 'speech',
    };
    final ref = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .add(data);

    debugPrint('✅ Saved lesson plan: users/$uid/lessonPlans/${ref.id}');
    return ref.id;
  }

  String _localeFor(String s) {
    final v = s.toLowerCase().trim();
    if (v == 'es' || v == 'spanish') return 'es-ES';
    if (v == 'ru' || v == 'russian') return 'ru-RU';
    if (v == 'pt' || v == 'portuguese') return 'pt-BR';
    if (v == 'ja' || v == 'japanese') return 'ja-JP';
    if (v == 'ko' || v == 'korean') return 'ko-KR';
    if (v == 'ro' || v == 'romanian') return 'ro-RO';
    if (v == 'fr' || v == 'french') return 'fr-FR';
    return 'en-US';
  }

  String _languageLabel(String s) {
    final v = s.toLowerCase().trim();
    if (v == 'es' || v == 'spanish') return 'Spanish';
    if (v == 'ru' || v == 'russian') return 'Russian';
    if (v == 'pt' || v == 'portuguese') return 'Portuguese';
    if (v == 'ja' || v == 'japanese') return 'Japanese';
    if (v == 'ko' || v == 'korean') return 'Korean';
    if (v == 'ro' || v == 'romanian') return 'Romanian';
    if (v == 'fr' || v == 'french') return 'French';
    return 'English';
  }

  String _starterQuestion(String lang) {
    final v = lang.toLowerCase().trim();
    if (v == 'es' || v == 'spanish') {
      return '¿Cómo te llamas y qué te gustaría practicar hoy?';
    }
    if (v == 'ru' || v == 'russian') {
      return 'Как тебя зовут и что ты хотел(а) бы сегодня потренировать?';
    }
    if (v == 'pt' || v == 'portuguese') {
      return 'Como você se chama e o que gostaria de praticar hoje?';
    }
    if (v == 'ja' || v == 'japanese') {
      return 'お名前は何ですか？今日は何を練習したいですか？';
    }
    if (v == 'ko' || v == 'korean') {
      return '이름이 뭐예요? 오늘 무엇을 연습하고 싶어요?';
    }
    if (v == 'ro' || v == 'romanian') {
      return 'Cum te numești și ce ai vrea să exersezi astăzi?';
    }
    if (v == 'fr' || v == 'french') {
      return 'Comment t’appelles-tu et qu’aimerais-tu pratiquer aujourd’hui ?';
    }
    return 'What is your name and what would you like to practice today?';
  }

  @override
  Widget build(BuildContext context) {
    final label = _languageLabel(widget.targetLanguage);
    final canStop = _isRecording && !_isProcessing;

    return Scaffold(
      appBar: AppBar(title: Text('Assessment – $label')),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 96,
              height: 96,
              child: ElevatedButton(
                onPressed: canStop ? _stopRecording : null,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(
                  Icons.mic,
                  size: 40,
                  color: canStop ? Colors.white : Colors.white54,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: Text(
                _status,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
