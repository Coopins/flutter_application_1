import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
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

  // Map stored language codes to friendly labels (7 languages).
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lesson Plan'),
        actions: [
          IconButton(
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
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: _loadLatest(),
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
          final md = (data['markdown'] ?? '') as String;
          final langLabel = _labelFromCode(langCode);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SingleChildScrollView(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyLarge!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Latest plan – $langLabel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Personalized Lesson Plan',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(md),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
