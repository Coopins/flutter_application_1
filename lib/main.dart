import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ignore: avoid_print
  print('✅ Firebase initialized for gab-and-go');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gab & Go',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // TODO: when your real Home screen is reconnected, replace HomeShell() with it.
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _listening = false;
  bool _ready = false;
  String _text = 'Tap “Init Mic”, then “Listen”.';

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final ok = await _stt.initialize(
        onStatus: (s) => setState(() => _text = 'Status: $s'),
        onError: (e) => setState(() => _text = 'Error: ${e.errorMsg}'),
      );
      setState(() {
        _ready = ok;
        _text = ok ? 'Mic ready.' : 'Mic init failed.';
      });
    } else {
      setState(() => _text = 'Mic permission denied.');
    }
  }

  Future<void> _toggleListen() async {
    if (!_ready) return;
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _stt.listen(
      onResult: (result) => setState(() => _text = result.recognizedWords),
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      cancelOnError: true,
    );
    setState(() => _listening = ok);
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gab & Go')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: _requestMic,
                  child: const Text('Init Mic'),
                ),
                FilledButton.tonal(
                  onPressed: _ready ? _toggleListen : null,
                  child: Text(_listening ? 'Stop' : 'Listen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
