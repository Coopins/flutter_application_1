import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class LessonsHubScreen extends StatelessWidget {
  const LessonsHubScreen({super.key});

  int _firstIncompleteIndex(Map<String, dynamic> plan, Set<int> completed) {
    final sections = (plan['sections'] as List?) ?? const [];
    for (var i = 0; i < sections.length; i++) {
      if (!completed.contains(i)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Lessons')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: FirestoreService.instance.streamPlans(uid: uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No lesson plans yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final lang = (data['language'] as String?) ?? 'Unknown';
              final ts = (data['createdAt'] as Timestamp?)?.toDate();
              final plan = (data['plan'] as Map<String, dynamic>?) ?? const {};
              final title = (plan['title'] as String?) ?? 'Lesson Plan';
              final sections = (plan['sections'] as List?) ?? const [];
              final total = sections.length;

              final progress =
                  (data['progress'] as Map<String, dynamic>?) ?? const {};
              final completed =
                  ((progress['completedSections'] as List?)?.cast<int>() ??
                          const <int>[])
                      .toSet();
              final done = completed.length;
              final resumeIndex = _firstIncompleteIndex(plan, completed);

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  [lang, if (ts != null) ts.toLocal().toString()].join(' • '),
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    _ProgressChip(done: done, total: total),
                    IconButton(
                      tooltip: 'Continue at section ${resumeIndex + 1}',
                      icon: const Icon(Icons.play_circle_fill),
                      onPressed: () {
                        // Open the player directly at the next section
                        Navigator.pushNamed(
                          context,
                          '/lessonPlayer',
                          arguments: {
                            'lessonId': d.id,
                            'language': lang,
                            'sectionIndex': resumeIndex,
                            'plan': plan,
                          },
                        );
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  // Build markdown from stored plan (for LessonPlanScreen)
                  final buf = StringBuffer()..writeln('# $title\n');
                  for (final s in sections) {
                    buf.writeln('## ${s['heading']}');
                    buf.writeln('${s['content']}\n');
                  }
                  Navigator.pushNamed(
                    context,
                    '/lessonPlan',
                    arguments: {
                      'lessonPlan': buf.toString(),
                      'lessonId': d.id,
                      'ttsLocale': _ttsCodeFor(lang),
                      'language': lang,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _ttsCodeFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'spanish':
        return 'es-ES';
      case 'french':
        return 'fr-FR';
      case 'german':
        return 'de-DE';
      case 'chinese':
        return 'cmn-CN';
      default:
        return 'en-US';
    }
  }
}

class _ProgressChip extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressChip({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final text = total == 0 ? '0/0' : '$done/$total';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
