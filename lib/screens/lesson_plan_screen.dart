// lib/screens/lesson_plan/lesson_plan_screen.dart

import 'package:flutter/material.dart';

class LessonPlanScreen extends StatelessWidget {
  static const routeName = '/lessonPlan';
  const LessonPlanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve selected language if passed
    final String? language =
        ModalRoute.of(context)?.settings.arguments as String?;

    // Sample lessons tailored for the user
    final List<Map<String, String>> lessons = [
      {
        'title': 'Lesson 1: Basics',
        'description': 'Greetings, introductions, and simple phrases.',
      },
      {
        'title': 'Lesson 2: Numbers',
        'description': 'Counting from 1 to 20 and basic math terms.',
      },
      {
        'title': 'Lesson 3: Food & Drink',
        'description': 'Vocabulary for ordering and dining out.',
      },
      {
        'title': 'Lesson 4: Travel',
        'description':
            'Asking for directions, transportation, and accommodation.',
      },
      {
        'title': 'Lesson 5: Conversation',
        'description': 'Everyday topics and small talk practice.',
      },
    ];

    return Scaffold(
      // Reverse AppBar colors: white background, black text/icons
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Lesson Plan',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (language != null) ...[
                  // Header card with reversed colors
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Plan for $language',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: ListView.separated(
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Reversed card background
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          title: Text(
                            lesson['title']!,
                            style: const TextStyle(
                              color: Colors.black, // Reversed text color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            lesson['description']!,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.black, // Reversed play icon
                              size: 32,
                            ),
                            onPressed: () {
                              // TODO: Start lesson
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
