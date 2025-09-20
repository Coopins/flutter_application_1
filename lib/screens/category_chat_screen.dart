// lib/screens/category_chat_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/openai_service.dart';

// === STT timing knobs ===
const kAfterTtsMicDelayMs = 1200; // wait after TTS before arming mic
const kListenMaxSeconds = 18; // total listen window
const kPauseForMs = 1600; // silence before auto-stop
const kMinListenWindowMs = 1200; // don't judge "no transcript" before this

class CategoryChatScreen extends StatefulWidget {
  const CategoryChatScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.languageCode, // 'es','fr','en'…
    this.ttsLocale = 'en-US',
    this.categoryTitle,
    this.languageLabel,
    this.systemPromptForCategory,
  });

  final String? categoryId;
  final String? categoryName;
  final String? languageCode;
  final String? ttsLocale;

  final String? categoryTitle;
  final String? languageLabel;
  final String? systemPromptForCategory;

  @override
  State<CategoryChatScreen> createState() => _CategoryChatScreenState();
}

class _CategoryChatScreenState extends State<CategoryChatScreen> {
  final _messages = <_Msg>[];
  final _scrollCtrl = ScrollController();

  final SpeechToText _stt = SpeechToText();
  final _tts = FlutterTts();

  bool _isProcessing = false;
  bool _isListening = false;
  bool _ttsBusy = false;
  bool _greeted = false;

  // STT helpers
  final _sttStopwatch = Stopwatch();
  bool _heardAnything = false;
  int _emptyTurns = 0;

  final _ai = OpenAIService.instance;

  @override
  void initState() {
    super.initState();
    _tts.awaitSpeakCompletion(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _greetOnce());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _stopAll();
    super.dispose();
  }

  String get _title {
    final chip = widget.categoryTitle ?? widget.categoryName ?? 'Conversation';
    final lang = widget.languageLabel ?? _languageLabel(widget.languageCode);
    return '$chip ($lang)';
  }

  String _languageLabel(String? code) {
    final v = (code ?? '').toLowerCase();
    switch (v) {
      case 'es':
        return 'Spanish';
      case 'ru':
        return 'Russian';
      case 'pt':
        return 'Portuguese';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'ro':
        return 'Romanian';
      case 'fr':
        return 'French';
      default:
        return 'English';
    }
  }

  Future<void> _greetOnce() async {
    if (_greeted) return;
    _greeted = true;

    final line = _greetingSentence();
    if (line.isEmpty) return;

    _addAssistantBubble(line);
    await _speak(line);

    await Future.delayed(const Duration(milliseconds: kAfterTtsMicDelayMs));
    await _startStt();
  }

  String _greetingSentence() {
    final cat = widget.categoryTitle ?? widget.categoryName ?? 'conversation';
    final iso = (widget.languageCode ?? 'en').toLowerCase();

    switch (iso) {
      case 'es':
        return 'Empecemos con $cat. ¿Qué te gustaría practicar?';
      case 'fr':
        return 'Commençons avec $cat. Qu’aimerais-tu pratiquer ?';
      case 'pt':
        return 'Vamos começar com $cat. O que você gostaria de praticar?';
      case 'ru':
        return 'Давай начнём с темы $cat. Что ты хочешь потренировать?';
      case 'ja':
        return '$cat から始めましょう。何を練習したいですか？';
      case 'ko':
        return '$cat 주제로 시작해 봅시다. 무엇을 연습하고 싶나요?';
      case 'ro':
        return 'Să începem cu $cat. Ce ai vrea să exersezi?';
      default:
        return 'Let’s start with $cat. What would you like to practice?';
    }
  }

  String _noTranscriptPrompt() {
    final iso = (widget.languageCode ?? 'en').toLowerCase();
    switch (iso) {
      case 'es':
        return 'No te escuché bien. ¿Puedes repetir, por favor?';
      case 'fr':
        return "Je n’ai pas bien entendu. Peux-tu répéter, s’il te plaît ?";
      case 'pt':
        return 'Não consegui ouvir bem. Pode repetir, por favor?';
      case 'ru':
        return 'Плохо расслышала. Повтори, пожалуйста.';
      case 'ja':
        return 'よく聞き取れませんでした。もう一度お願いします。';
      case 'ko':
        return '잘 듣지 못했어요. 한 번 더 말씀해 주실래요?';
      case 'ro':
        return 'Nu am auzit bine. Poți repeta, te rog?';
      default:
        return 'I didn’t catch that. Could you repeat, please?';
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _addUserBubble(String text) {
    if (!mounted) return;
    setState(() => _messages.add(_Msg(fromUser: true, text: text)));
    _scrollToEnd();
  }

  void _addAssistantBubble(String text) {
    if (!mounted) return;
    setState(() => _messages.add(_Msg(fromUser: false, text: text)));
    _scrollToEnd();
  }

  Future<void> _speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      if (mounted) setState(() => _ttsBusy = true);
      await _tts.stop();
      await _tts.setLanguage(widget.ttsLocale ?? 'en-US');
      await _tts.setSpeechRate(0.40);
      await _tts.setPitch(1.0);
      await _tts.speak(trimmed);
    } catch (e) {
      _showSnack('TTS error: $e');
    } finally {
      if (mounted) setState(() => _ttsBusy = false);
    }
  }

  Future<bool> _ensureMic() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    status = await Permission.microphone.request();
    if (status.isGranted) return true;

    _showSnack('Microphone permission is required.');
    return false;
  }

  String? _pickBestSttLocale(String? iso) {
    switch ((iso ?? '').toLowerCase()) {
      case 'es':
        return 'es-US'; // matches your offline pack
      case 'fr':
        return 'fr-FR';
      case 'pt':
        return 'pt-BR';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'ru':
        return 'ru-RU';
      case 'ro':
        return 'ro-RO';
      case 'en':
        return 'en-US';
      default:
        return null;
    }
  }

  Future<void> _startStt() async {
    if (_isListening) return;
    if (!await _ensureMic()) return;

    final available = await _stt.initialize(
      onStatus: (s) => debugPrint('🎤 status: $s'),
      onError: (e) => debugPrint('🎤 error: $e'),
    );
    if (!available) {
      _showSnack('Speech not available on this device.');
      return;
    }

    _heardAnything = false;
    _sttStopwatch
      ..reset()
      ..start();

    final localeId = _pickBestSttLocale(widget.languageCode);

    final ok = await _stt.listen(
      onResult: _onSttResult,
      onSoundLevelChange: (level) {
        if (level > 1.5) _heardAnything = true;
      },
      localeId: localeId,
      listenFor: Duration(seconds: kListenMaxSeconds),
      pauseFor: const Duration(milliseconds: kPauseForMs),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
      // NOTE: autoPunctuation not available in 7.3.0
    );

    if (mounted) setState(() => _isListening = ok);

    debugPrint(
      '🎤 STT listening… ($localeId) max=${kListenMaxSeconds}s pause=${kPauseForMs}ms ok=$ok',
    );
  }

  Future<void> _stopStt() async {
    if (!_isListening) return;
    try {
      await _stt.stop();
    } catch (_) {
      // ignore
    } finally {
      _sttStopwatch.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _stopAll() async {
    try {
      await _stt.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    _sttStopwatch.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _ttsBusy = false;
      });
    }
  }

  Future<void> _onSttResult(SpeechRecognitionResult r) async {
    final text = r.recognizedWords.trim();
    if (text.isNotEmpty) _heardAnything = true;

    if (!r.finalResult) return;

    _sttStopwatch.stop();
    final elapsed = _sttStopwatch.elapsedMilliseconds;

    if (text.isEmpty && (!_heardAnything || elapsed < kMinListenWindowMs)) {
      debugPrint(
        '🕒 Early stop with no speech (elapsed=${elapsed}ms). Re-arming.',
      );
      await Future.delayed(const Duration(milliseconds: 150));
      await _startStt();
      return;
    }

    if (text.isEmpty) {
      _emptyTurns++;
      if (_emptyTurns % 2 == 1) {
        final prompt = _noTranscriptPrompt();
        _addAssistantBubble(prompt);
        await _speak(prompt);
      }
      await Future.delayed(const Duration(milliseconds: kAfterTtsMicDelayMs));
      await _startStt();
      return;
    }

    _emptyTurns = 0;
    _addUserBubble(text);

    if (mounted) setState(() => _isProcessing = true);
    try {
      final reply = (await _ai.chat(_systemPrompt(), text)).trim();
      final safeReply =
          reply.isEmpty
              ? 'Got it. Would you like to continue with this topic?'
              : reply;

      _addAssistantBubble(safeReply);
      await _speak(safeReply);
    } catch (e) {
      _showSnack('Processing error: $e');
      debugPrint('⚠️ processing error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
      await Future.delayed(const Duration(milliseconds: kAfterTtsMicDelayMs));
      await _startStt();
    }
  }

  String _systemPrompt() {
    final custom = (widget.systemPromptForCategory ?? '').trim();
    if (custom.isNotEmpty) return custom;

    final lang = widget.languageLabel ?? _languageLabel(widget.languageCode);
    final category =
        widget.categoryTitle ?? widget.categoryName ?? 'Conversation';
    final iso = (widget.languageCode ?? 'en').toLowerCase();

    return '''
You are Gabi, a friendly, concise language coach.
- Stay within the topic: "$category".
- Speak primarily in $lang; switch to brief English only to clarify if the user is lost.
- Keep replies short (2–4 sentences) and ask 1 guiding question.
- Avoid markdown headings; simple paragraphs and short lists are OK.
- If the user code-switches, answer in $lang but acknowledge what they said.
- Language code hint: "$iso".
''';
  }

  Future<void> _onMicPressed() async {
    if (_ttsBusy || _isProcessing) return;
    if (_isListening) {
      await _stopStt();
    } else {
      await _startStt();
    }
  }

  Future<void> _onStopPressed() async {
    await _stopAll();
    _showSnack('Stopped. Tap the mic to listen again.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: _isProcessing ? MediaQuery.of(context).size.width * 0.65 : 0,
            color: theme.colorScheme.secondary,
            margin: const EdgeInsets.only(top: 2),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final align =
                    m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
                final bg =
                    m.fromUser
                        ? Colors.deepPurple.shade400.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.06);
                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      m.text,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Processing…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton.filled(
                    onPressed:
                        (_isProcessing || _ttsBusy) ? null : _onMicPressed,
                    icon: Icon(_isListening ? Icons.stop_circle : Icons.mic),
                    tooltip:
                        _isListening ? 'Stop listening' : 'Start listening',
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _onStopPressed,
                    icon: const Icon(Icons.stop),
                    tooltip: 'Stop TTS & listening',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String id;
  final bool fromUser;
  final String text;

  _Msg({String? id, required this.fromUser, required this.text})
    : id = id ?? UniqueKey().toString();

  _Msg copyWith({String? id, bool? fromUser, String? text}) => _Msg(
    id: id ?? this.id,
    fromUser: fromUser ?? this.fromUser,
    text: text ?? this.text,
  );
}
