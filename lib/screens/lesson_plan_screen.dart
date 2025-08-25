// lib/screens/lesson_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
  final FlutterTts _tts = FlutterTts();

  String _markdown = '';
  String? _lessonId;
  String _ttsLocale = 'en-US';
  String _language = 'Spanish';

  bool _loading = true;
  bool _expanded = true;
  bool _langPassed = false; // true if a language arg was provided

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _lessonId = args['lessonId'] as String?;
    _langPassed = args.containsKey('language');
    _language = (args['language'] as String?) ?? _language;
    _ttsLocale = (args['ttsLocale'] as String?) ?? _ttsLocale;

    _initTts();
    _fetchLessonPlan();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(_ttsLocale);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _fetchLessonPlan() async {
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _markdown = '';
        _loading = false;
      });
      return;
    }

    final col = FirebaseFirestore.instance
        .collection('lessonPlans')
        .doc(user.uid)
        .collection('items');

    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;

      if (_lessonId != null) {
        doc = await col.doc(_lessonId!).get();
      } else {
        // If language provided, show latest for that language; else latest overall
        Query<Map<String, dynamic>> q = col
            .orderBy('createdAt', descending: true)
            .limit(1);
        if (_langPassed) {
          q = col
              .where('language', isEqualTo: _language)
              .orderBy('createdAt', descending: true)
              .limit(1);
        }
        final snap = await q.get();
        if (snap.docs.isNotEmpty) {
          doc = snap.docs.first;
          _lessonId = doc.id;
        }
      }

      setState(() {
        _markdown = (doc?.data()?['markdown'] as String?)?.trim() ?? '';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _markdown = '';
        _loading = false;
      });
    }
  }

  Future<void> _speak() async {
    if (_markdown.trim().isEmpty) return;
    final plain = _markdown
        .replaceAll(RegExp(r'[#*_>`\-]'), '')
        .replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), r'\1');
    await _tts.stop();
    await _tts.speak(plain);
  }

  @override
  void dispose() {
    _tts.stop(); // flutter_tts has no dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purple = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Lesson Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: _speak,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLessonPlan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _langPassed ? _language : 'Latest',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            _buildPanel(theme),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 64,
          child: Material(
            color: purple,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (r) => false);
              },
              splashColor: Colors.white24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.home_filled, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(ThemeData theme) {
    return Card(
      color: const Color(0xFF1A1F29),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white70,
        title: Text(
          'Overview',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (!_loading && _markdown.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                '(Empty)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          if (_markdown.trim().isNotEmpty)
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF141923),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: MarkdownBody(
                selectable: true,
                data: _markdown,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: const TextStyle(color: Colors.white),
                  h1: const TextStyle(color: Colors.white, fontSize: 22),
                  h2: const TextStyle(color: Colors.white, fontSize: 20),
                  h3: const TextStyle(color: Colors.white, fontSize: 18),
                  listBullet: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _speak,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Listen'),
          ),
        ],
      ),
    );
  }
}
