import 'package:flutter/material.dart';

class LessonChatScreen extends StatelessWidget {
  const LessonChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final title = (args['title'] ?? 'Lesson') as String;
    final language = (args['language'] ?? '') as String;
    final plan = args['plan'] as Map<String, dynamic>?;
    final method = (args['method'] ?? 'starter') as String;
    final lessonId = (args['lessonId'] ?? '') as String;

    final lessons =
        (plan?['lessons'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: [
          if (method != 'personalized')
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/fluencyAssessment',
                  arguments: {
                    'selectedLanguage': language,
                    'lessonId': lessonId,
                  },
                );
              },
              icon: const Icon(Icons.mic, color: Colors.white70, size: 18),
              label: const Text(
                'Personalize',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            plan == null
                ? const Center(
                  child: Text(
                    'No plan data found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language: $language',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (plan['description'] ?? '') as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lessons',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: lessons.length,
                        separatorBuilder:
                            (_, __) => const Divider(color: Colors.white24),
                        itemBuilder: (_, i) {
                          final l = lessons[i];
                          final lt = (l['title'] ?? 'Untitled') as String;
                          final objectives =
                              (l['objectives'] as List?)?.cast<String>() ??
                              const [];
                          final steps =
                              (l['steps'] as List?)?.cast<String>() ?? const [];
                          final est = (l['estimatedMinutes'] ?? 20).toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lt,
                                  style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (objectives.isNotEmpty)
                                  Text(
                                    'Objectives: ${objectives.join(", ")}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                if (steps.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Steps:',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  ...steps.map(
                                    (s) => Text(
                                      '• $s',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Estimated: $est min',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
