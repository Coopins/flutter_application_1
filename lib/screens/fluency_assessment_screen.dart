import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import '../routes.dart';
import '../services/stt_service.dart';
import '../services/lesson_plan_service.dart';

class FluencyAssessmentScreen extends StatefulWidget {
  /// Pass a language CODE: 'es','ru','pt','ja','ko','ro','fr' (or 'en').
  final String targetLanguage;

  const FluencyAssessmentScreen({super.key, this.targetLanguage = 'en'});

  @override
  State<FluencyAssessmentScreen> createState() =>
      _FluencyAssessmentScreenState();
}

class _FluencyAssessmentScreenState extends State<FluencyAssessmentScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _status = 'Preparing…';
  String? _recordingPath;

  // Hard cap so recording can't run forever if user forgets to stop.
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
    super.dispose();
  }

  // Intro (EN) -> Question (target language) -> Auto-start recording (mic ONLY stops).
  Future<void> _runIntroThenListen() async {
    try {
      setState(() => _status = 'Getting ready…');

      await _tts.awaitSpeakCompletion(true);

      // English intro
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1.0);
      await _tts.speak("Let's get started. I’ll ask you a quick question.");

      // Target-language question
      final ttsLocale = _localeFor(widget.targetLanguage);
      final question = _starterQuestion(widget.targetLanguage);
      await _tts.setLanguage(ttsLocale);
      await _tts.speak(question);

      // Auto-start recording (tap mic ONLY to stop)
      await _startRecording();
      setState(() => _status = 'Listening… Tap the mic to stop.');
    } catch (e) {
      setState(() => _status = 'TTS/init failed: $e');
    }
  }

  // --- Preflight helpers -----------------------------------------------------

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final req = await Permission.microphone.request();
    if (req.isGranted) return true;

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Microphone permission is required.'),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
    return false;
  }

  Future<bool> _storageWritableProbe() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final test = File(
        '${dir.path}/.__gab_probe_${DateTime.now().millisecondsSinceEpoch}',
      );
      await test.create(recursive: true);
      await test.writeAsBytes(const []);
      await test.delete();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Storage unavailable: $e')));
      setState(() => _status = 'Storage unavailable.');
      return false;
    }
  }

  // --- Recording -------------------------------------------------------------

  Future<void> _startRecording() async {
    try {
      // Preflight: mic permission + writable storage
      if (!await _ensureMicPermission()) return;
      if (!await _storageWritableProbe()) return;

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // better for Whisper
          sampleRate: 48000, // clean capture
          numChannels: 1, // mono
        ),
        path: filePath,
      );

      _recordingPath = filePath;
      setState(() => _isRecording = true);

      // Hard-stop safety timer
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

      final stoppedPath = await _recorder.stop();
      _isRecording = false;
      if (stoppedPath != null && stoppedPath.isNotEmpty) {
        _recordingPath = stoppedPath;
      }
      setState(() => _status = 'Generating your lesson plan…');
      if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
        setState(() => _status = 'No audio captured.');
        return;
      }
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

      final stt = STTService(apiKey: apiKey);
      final lp = LessonPlanService(apiKey: apiKey);

      // 1) Transcribe with Whisper
      final transcript = await stt.transcribe(
        File(path),
        languageCode: widget.targetLanguage,
      );

      // 2) Generate structured Markdown lesson plan
      final planMarkdown = await lp.generatePlan(
        transcript: transcript,
        languageCode: widget.targetLanguage,
      );

      // 3) Save to Firestore (non-blocking for UX if it fails)
      String? docId;
      try {
        docId = await _saveLessonPlan(
          planMarkdown,
          language: widget.targetLanguage,
          ttsLocale: _localeFor(widget.targetLanguage),
        );
      } catch (_) {}

      // 4) Navigate to Lesson Plan screen
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
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final now = FieldValue.serverTimestamp();
    final ref = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .add({
          'language': language, // 'es','ru','pt','ja','ko','ro','fr'
          'markdown': markdown,
          'ttsLocale': ttsLocale,
          'createdAt': now,
          'updatedAt': now,
        });
    debugPrint('✅ Saved lesson plan: users/$uid/lessonPlans/${ref.id}');
    return ref.id;
  }

  // ------- Helpers for the 7 languages -------
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
