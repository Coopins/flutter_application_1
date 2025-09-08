import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonPlanStorage {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Saves under users/{uid}/lessonPlans/{autoId}
  static Future<String> savePlan({
    required String markdown,
    required String language,
    required String ttsLocale,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final data = <String, dynamic>{
      'markdown': markdown,
      'language': language,
      'ttsLocale': ttsLocale,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .add(data);

    return doc.id;
  }

  /// Stream newest first for the signed-in user
  static Stream<QuerySnapshot<Map<String, dynamic>>> myPlansStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
