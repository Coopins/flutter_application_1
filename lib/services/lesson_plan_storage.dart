// lib/services/lesson_plan_storage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonPlanStorage {
  /// Saves a plan and returns the document id.
  static Future<String> savePlan({
    required String markdown,
    required String language,
    String? ttsLocale,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not signed in');
    }

    final col = FirebaseFirestore.instance
        .collection('lessonPlans')
        .doc(user.uid)
        .collection('items');

    final data = <String, dynamic>{
      'markdown': markdown,
      'plan':
          markdown, // <-- optional mirror field (for readers that expect 'plan')
      'language': language,
      if (ttsLocale != null) 'ttsLocale': ttsLocale,
      'source': 'gabi',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final doc = await col.add(data);
    return doc.id;
  }
}
