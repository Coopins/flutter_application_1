// lib/services/lesson_plan_storage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonPlanStorage {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Saves a lesson plan document under users/{uid}/lessonPlans/{autoId}
  /// Returns the new document id.
  static Future<String> savePlan({
    required String markdown,
    required String language,
    String ttsLocale = 'en-US',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      // Anonymous sign-in is ok if your app flow allows it; otherwise throw.
      await _auth.signInAnonymously();
    }
    final uid = (_auth.currentUser ?? user)!.uid;

    final col = _db.collection('users').doc(uid).collection('lessonPlans');
    final docRef = col.doc(); // auto id

    await docRef.set({
      'language': language.trim(),
      'markdown': markdown,
      'ttsLocale': ttsLocale,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Fetch a single plan.
  static Future<Map<String, dynamic>?> getPlan(String id) async {
    final uid = _requireUid();
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(id)
        .get();
    return snap.data();
  }

  /// List plans (newest first).
  static Future<List<Map<String, dynamic>>> listPlans({int limit = 50}) async {
    final uid = _requireUid();
    final q = await _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Update plan text/locale.
  static Future<void> updatePlan({
    required String id,
    String? markdown,
    String? language,
    String? ttsLocale,
  }) async {
    final uid = _requireUid();
    final data = <String, dynamic>{};
    if (markdown != null) data['markdown'] = markdown;
    if (language != null) data['language'] = language;
    if (ttsLocale != null) data['ttsLocale'] = ttsLocale;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(id)
        .update(data);
  }

  static String _requireUid() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw StateError('Not signed in');
    }
    return u.uid;
  }
}
