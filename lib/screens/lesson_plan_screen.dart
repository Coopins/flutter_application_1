// lib/screens/lesson_plan_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/category.dart';
import '../models/phrase.dart';
import '../models/vocab.dart';
import '../routes.dart';
import '../services/category_repository.dart';
import 'category_chat_screen.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scroll = ScrollController();

  bool _isSpeaking = false;

  String? _fullMarkdown;
  String? _ttsLocale;
  String _langLabel = 'English';

  // Parsed sections
  List<_PlanSection> _sections = [];

  // Jump-to & "remember" state (session only)
  final Map<String, GlobalKey> _sectionKeys = {};
  static String? _lastOpenTitle;
  static final Map<String, bool> _expandedMemory = {}; // title -> expanded

  @override
  void dispose() {
    _tts.stop();
    _scroll.dispose();
    super.dispose();
  }

  // -------- Firestore loads --------

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadLatest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('lessonPlans')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || id.isEmpty) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('lessonPlans')
            .doc(id)
            .get();

    return doc.exists ? doc : null;
  }

  // -------- Labels / locales --------

  String _labelFromCode(String code) {
    switch (code.toLowerCase()) {
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

  String _localeFrom(String? codeOrLocale) {
    final s = (codeOrLocale ?? '').toLowerCase();
    if (s.contains('es') || s == 'es') return 'es-ES';
    if (s.contains('ru') || s == 'ru') return 'ru-RU';
    if (s.contains('pt') || s == 'pt') return 'pt-BR';
    if (s.contains('ja') || s == 'ja') return 'ja-JP';
    if (s.contains('ko') || s == 'ko') return 'ko-KR';
    if (s.contains('ro') || s == 'ro') return 'ro-RO';
    if (s.contains('fr') || s == 'fr') return 'fr-FR';
    return 'en-US';
  }

  // -------- TTS helpers --------

  String _markdownToSpeech(String md) {
    var t = md;

    final heading = RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true);
    final bold = RegExp(r'\*\*([^*]+)\*\*');
    final ital = RegExp(r'\*([^*\n]+)\*');
    final code = RegExp(r'`([^`]+)`');
    final quote = RegExp(r'^\s{0,3}>\s?', multiLine: true);
    final link = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    final ul = RegExp(r'^\s*[-*+]\s+', multiLine: true);
    final ol = RegExp(r'^\s*\d+\.\s+', multiLine: true);

    t = t.replaceAll(heading, '');
    t = t.replaceAll(bold, r'$1');
    t = t.replaceAll(ital, r'$1');
    t = t.replaceAll(code, r'$1');
    t = t.replaceAll(quote, '');
    t = t.replaceAll(link, r'$1');
    t = t.replaceAll(ul, '• ');
    t = t.replaceAll(ol, '• ');

    t = t.replaceAll('\r', '');
    return t.trim();
  }

  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_ttsLocale ?? 'en-US');
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      if (mounted) setState(() => _isSpeaking = true);
      await _tts.speak(text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('TTS error: $e')));
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _speakFullPlan() async {
    if (_fullMarkdown == null) return;
    await _speakText(_markdownToSpeech(_fullMarkdown!));
  }

  Future<void> _speakSection(_PlanSection s) async {
    await _speakText(_markdownToSpeech(s.content));
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  // -------- Markdown parsing into sections --------

  static const List<String> _order = [
    'overview',
    'goals',
    'key focus areas',
    'key phrases',
    'mini-dialogue',
    'mini dialogue',
    'pronunciation tips',
    'grammar bite',
    'drills',
    'comprehension checks',
    'homework',
    'summary',
    'other',
  ];

  List<_PlanSection> _splitMarkdownToSections(String md) {
    final lines = md.split('\n');

    final List<_PlanSection> raw = [];
    String? currentTitle;
    final buffer = StringBuffer();

    bool seenSection = false;
    final headerRx = RegExp(r'^\s*#{2,3}\s+(.+)\s*$');

    for (final line in lines) {
      final m = headerRx.firstMatch(line);
      if (m != null) {
        if (currentTitle != null) {
          raw.add(
            _PlanSection(
              title: currentTitle,
              content: buffer.toString().trim(),
            ),
          );
          buffer.clear();
        } else if (!seenSection && buffer.isNotEmpty) {
          raw.add(
            _PlanSection(title: 'Overview', content: buffer.toString().trim()),
          );
          buffer.clear();
        }
        final captured = m.group(1) ?? '';
        currentTitle = captured.trim();
        seenSection = true;
      } else {
        buffer.writeln(line);
      }
    }
    if (currentTitle != null) {
      raw.add(
        _PlanSection(title: currentTitle, content: buffer.toString().trim()),
      );
    } else {
      if (buffer.isNotEmpty) {
        raw.add(
          _PlanSection(title: 'Overview', content: buffer.toString().trim()),
        );
      }
    }

    for (var i = 0; i < raw.length; i++) {
      raw[i] = raw[i].copyWith(title: _canon(raw[i].title));
    }

    raw.sort((a, b) {
      final ai = _order.indexOf(a.title.toLowerCase());
      final bi = _order.indexOf(b.title.toLowerCase());
      final aa = ai == -1 ? 999 : ai;
      final bb = bi == -1 ? 999 : bi;
      return aa.compareTo(bb);
    });

    final List<_PlanSection> merged = [];
    for (final s in raw) {
      if (merged.isNotEmpty &&
          merged.last.title.toLowerCase() == s.title.toLowerCase()) {
        merged.last = merged.last.copyWith(
          content: '${merged.last.content}\n\n${s.content}'.trim(),
        );
      } else {
        merged.add(s);
      }
    }

    if (merged.isEmpty) {
      merged.add(_PlanSection(title: 'Overview', content: md));
    }
    return merged;
  }

  String _canon(String title) {
    final t = title.trim().toLowerCase();
    if (t.contains('key focus')) return 'Key Focus Areas';
    if (t.contains('key phrase')) return 'Key Phrases';
    if (t.contains('mini') && t.contains('dialog')) return 'Mini-Dialogue';
    if (t.contains('pronunciation')) return 'Pronunciation Tips';
    if (t.contains('grammar')) return 'Grammar Bite';
    if (t.contains('drill')) return 'Drills';
    if (t.contains('comprehension')) return 'Comprehension Checks';
    if (t.contains('homework') || t.contains('practice at home'))
      return 'Homework';
    if (t.contains('goal')) return 'Goals';
    if (t.contains('summary')) return 'Summary';
    if (t.contains('overview') || t.contains('lesson plan')) return 'Overview';
    return title.trim().isEmpty ? 'Other' : _toTitleCase(title.trim());
  }

  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  // -------- precise scroll helper --------

  void _scrollToTitle(String title) {
    final key = _sectionKeys[title];
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      final ro = ctx.findRenderObject();
      if (ro is! RenderObject) return;

      final viewport = RenderAbstractViewport.of(ro);
      if (!_scroll.hasClients) return;

      final target = viewport.getOffsetToReveal(ro, 0.10).offset;
      final min = _scroll.position.minScrollExtent;
      final max = _scroll.position.maxScrollExtent;
      final clamped = target.clamp(min, max);

      _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  // -------- UI --------

  @override
  Widget build(BuildContext context) {
    String? docId;
    String? focusSection;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args['docId'] is String) {
        final v = (args['docId'] as String).trim();
        docId = v.isEmpty ? null : v;
      }
      if (args['focusSection'] is String) {
        focusSection = _canon(args['focusSection'] as String);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lesson Plan'),
        actions: [
          Semantics(
            label: 'Play full plan',
            button: true,
            child: IconButton(
              tooltip: 'Play',
              icon: const Icon(Icons.play_arrow),
              onPressed:
                  _isSpeaking || _fullMarkdown == null ? null : _speakFullPlan,
            ),
          ),
          Semantics(
            label: 'Stop speaking',
            button: true,
            child: IconButton(
              tooltip: 'Stop',
              icon: const Icon(Icons.stop),
              onPressed: _isSpeaking ? _stopSpeaking : null,
            ),
          ),
          Semantics(
            label: 'Go home',
            button: true,
            child: IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (_) => false,
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: docId != null ? _loadById(docId) : _loadLatest(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(child: Text('No lesson plans yet.'));
          }
          final data = doc.data()!;
          final langCode = (data['language'] ?? 'en') as String;
          final md =
              (data['markdown'] ?? data['classicMarkdown'] ?? '') as String;
          final savedLocale = data['ttsLocale'] as String?;

          _langLabel = _labelFromCode(langCode);
          _ttsLocale = _localeFrom(savedLocale ?? langCode);
          _fullMarkdown = md;
          _sections = _splitMarkdownToSections(md);

          _sectionKeys.clear();
          for (final s in _sections) {
            _sectionKeys[s.title] = GlobalKey();
          }

          final desired = focusSection ?? _lastOpenTitle;
          if (desired != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToTitle(desired),
            );
          }

          final uid = FirebaseAuth.instance.currentUser!.uid;
          final repo = CategoryRepository(FirebaseFirestore.instance);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ListView(
              controller: _scroll,
              children: [
                Center(
                  child: Text(
                    'Personalized Lesson Plan – $_langLabel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                StreamBuilder<List<Category>>(
                  stream: repo.watch(uid, doc.id),
                  builder: (context, snap) {
                    final chips = <Widget>[];

                    // De-dupe live categories by case-insensitive name
                    final live = snap.data ?? const <Category>[];
                    final byName = <String, Category>{};
                    for (final c in live) {
                      final key = c.name.trim().toLowerCase();
                      if (!byName.containsKey(key)) {
                        byName[key] = c;
                      } else {
                        // Prefer lower order if duplicates exist
                        if (c.order < byName[key]!.order) {
                          byName[key] = c;
                        }
                      }
                    }
                    final liveUnique =
                        byName.values.toList()
                          ..sort((a, b) => a.order.compareTo(b.order));

                    final existingNames =
                        liveUnique
                            .map((c) => c.name.trim().toLowerCase())
                            .toSet();

                    if (snap.connectionState == ConnectionState.waiting) {
                      chips.add(
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    // Render existing categories (unique)
                    chips.addAll(
                      liveUnique.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(c.name),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => CategoryChatScreen(
                                        categoryId: c.id,
                                        categoryTitle: c.name, // chip title
                                        languageLabel:
                                            _langLabel, // chosen language label
                                        systemPromptForCategory:
                                            c.chatSystemPrompt ??
                                            'You are Gabi. Stay within the “${c.name}” topic and keep replies concise, scaffolded, and encouraging.',
                                        ttsLocale: _ttsLocale ?? 'en-US',
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );

                    // Suggested categories (no '+')
                    final suggested = <_SuggestedCategory>[
                      _SuggestedCategory.hardcoded(
                        'Hobbies',
                        goals: const ['Discuss hobbies', 'Ask about interests'],
                        phrases: const [
                          Phrase(phrase: 'Me gusta…', translation: 'I like…'),
                          Phrase(
                            phrase: '¿Qué te gusta hacer?',
                            translation: 'What do you like to do?',
                          ),
                        ],
                        vocab: const [
                          Vocab(term: 'leer', translation: 'to read'),
                          Vocab(term: 'deportes', translation: 'sports'),
                        ],
                        tasks: const [
                          'Tell Gabi about two hobbies you enjoy.',
                          'Ask Gabi about a hobby and follow up with a question.',
                        ],
                        prompt:
                            'You are Gabi. Coach only within hobbies and interests.',
                      ),
                      _SuggestedCategory.hardcoded(
                        'Travel',
                        goals: const ['Ask for directions', 'Book tickets'],
                        phrases: const [
                          Phrase(
                            phrase: '¿Dónde está…?',
                            translation: 'Where is…?',
                          ),
                        ],
                        vocab: const [
                          Vocab(term: 'billete', translation: 'ticket'),
                          Vocab(term: 'estación', translation: 'station'),
                        ],
                        tasks: const [
                          'Ask for directions to a museum.',
                          'Book a train ticket for tomorrow.',
                        ],
                        prompt:
                            'You are Gabi. Coach only travel scenarios (directions, tickets, hotels).',
                      ),
                      _SuggestedCategory.hardcoded(
                        'Shopping',
                        goals: const ['Ask prices', 'Compare items'],
                        phrases: const [
                          Phrase(
                            phrase: '¿Cuánto cuesta?',
                            translation: 'How much is it?',
                          ),
                        ],
                        vocab: const [
                          Vocab(term: 'caro', translation: 'expensive'),
                          Vocab(term: 'barato', translation: 'cheap'),
                        ],
                        tasks: const [
                          'Ask the price of two items and compare them.',
                        ],
                        prompt:
                            'You are Gabi. Coach only shopping and bargaining conversations.',
                      ),
                      _SuggestedCategory.hardcoded(
                        'Directions',
                        goals: const ['Follow and give directions'],
                        phrases: const [
                          Phrase(
                            phrase: 'a la derecha',
                            translation: 'to the right',
                          ),
                        ],
                        vocab: const [
                          Vocab(term: 'esquina', translation: 'corner'),
                        ],
                        tasks: const [
                          'Ask Gabi for directions to a café and repeat them back.',
                        ],
                        prompt:
                            'You are Gabi. Coach only directions and navigation.',
                      ),
                    ];

                    for (final s in suggested) {
                      if (!existingNames.contains(s.name.toLowerCase())) {
                        chips.add(
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(s.name),
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                final created = await _createSuggestedCategory(
                                  uid,
                                  doc.id,
                                  s,
                                );
                                if (!mounted) return;
                                nav.push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CategoryChatScreen(
                                          categoryId: created.id,
                                          categoryTitle: created.name,
                                          languageLabel: _langLabel,
                                          systemPromptForCategory:
                                              created.chatSystemPrompt ??
                                              'You are Gabi. Stay within the “${created.name}” topic and keep replies concise, scaffolded, and encouraging.',
                                          ttsLocale: _ttsLocale ?? 'en-US',
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: chips),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Sections
                ..._sections.map(
                  (s) => _SectionCard(
                    containerKey: _sectionKeys[s.title]!,
                    section: s,
                    initiallyExpanded: _expandedMemory[s.title] ?? true,
                    onExpandedChanged: (expanded) {
                      _expandedMemory[s.title] = expanded;
                      if (expanded) _lastOpenTitle = s.title;
                    },
                    onListen: () => _speakSection(s),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Category> _createSuggestedCategory(
    String uid,
    String planId,
    _SuggestedCategory s,
  ) async {
    final repo = CategoryRepository(FirebaseFirestore.instance);
    final cat = Category(
      id: s.id,
      name: s.name,
      order: s.order,
      goals: s.goals,
      keyPhrases: s.phrases,
      vocab: s.vocab,
      practiceTasks: s.tasks,
      chatSystemPrompt: s.prompt,
    );
    await repo.upsert(uid, planId, cat);
    return cat;
  }
}

// --- helpers for suggested create-on-tap
class _SuggestedCategory {
  final String id;
  final String name;
  final int order;
  final List<String> goals;
  final List<Phrase> phrases;
  final List<Vocab> vocab;
  final List<String> tasks;
  final String prompt;

  _SuggestedCategory.hardcoded(
    this.name, {
    required this.goals,
    required List<Phrase> phrases,
    required List<Vocab> vocab,
    required this.tasks,
    required this.prompt,
  }) : order = 99,
       id = name.toLowerCase().replaceAll(' ', '_'),
       phrases = List.unmodifiable(phrases),
       vocab = List.unmodifiable(vocab);
}

// ===== Section UI =====

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.containerKey,
    required this.section,
    required this.onListen,
    required this.initiallyExpanded,
    required this.onExpandedChanged,
  });

  final GlobalKey containerKey;
  final _PlanSection section;
  final VoidCallback onListen;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final onSurface = scheme.onSurface.withValues(alpha: 0.86);

    return Container(
      key: widget.containerKey,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) {
            setState(() => _expanded = v);
            widget.onExpandedChanged(v);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            widget.section.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          children: [
            Container(
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: widget.section.content,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: onSurface),
                      listBullet: Theme.of(context).textTheme.bodyLarge,
                      blockquotePadding: const EdgeInsets.all(8),
                      blockquoteDecoration: BoxDecoration(
                        color: surface.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Listen to ${widget.section.title}',
                    button: true,
                    child: TextButton.icon(
                      onPressed: widget.onListen,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Listen'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSection {
  final String title;
  final String content;
  const _PlanSection({required this.title, required this.content});

  _PlanSection copyWith({String? title, String? content}) => _PlanSection(
    title: title ?? this.title,
    content: content ?? this.content,
  );
}
