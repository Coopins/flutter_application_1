import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('✅ Firebase initialized for gab-and-go');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gab & Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Gab & Go Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttAvailable = false;
  bool _listening = false;
  String _text = '';
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Request mic permission
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() => _status = 'Microphone permission denied');
      return;
    }

    // Init STT
    _sttAvailable = await _speech.initialize(
      onStatus:
          (s) => setState(() {
            _listening = s == 'listening';
            _status = 'STT status: $s';
          }),
      onError: (e) => setState(() => _status = 'STT error: ${e.errorMsg}'),
    );

    if (!_sttAvailable) setState(() => _status = 'Speech not available');
  }

  Future<void> _start() async {
    if (!_sttAvailable) return;
    setState(() => _status = 'Listening…');
    await _speech.listen(
      onResult: (r) => setState(() => _text = r.recognizedWords),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> _stop() async {
    await _speech.stop();
    setState(() {
      _listening = false;
      _status = 'Stopped';
    });
  }

  Future<void> _speakBack() async {
    if (_text.trim().isEmpty) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_text);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: cs.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _listening ? null : _start,
                  child: const Text('Start STT'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _listening ? _stop : null,
                  child: const Text('Stop STT'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _speakBack,
                  child: const Text('Speak Back'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_status, style: TextStyle(color: cs.primary)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _text.isEmpty ? 'Say something…' : _text,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
