import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonPlanStorage {
  static bool _saving = false;

  static Future<String> savePlan({
    required String markdown,
    required String language,
  }) async {
    if (_saving) throw Exception('Save already in progress');
    _saving = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('lessonPlans');

      final doc = await col.add({
        'markdown': markdown.trim(),
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } finally {
      _saving = false;
    }
  }
}
