import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save a lesson plan document and return its ID.
  /// Also initializes a lightweight progress object so we can resume later.
  Future<String> saveLessonPlan({
    required String uid,
    required String language,
    required Map<String, dynamic> plan,
    required String method,
    required String transcript,
  }) async {
    final docRef = await _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .add({
          'language': language,
          'method': method,
          'transcript': transcript,
          'plan': plan,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Keep progress embedded to avoid extra reads/collections.
          'progress': {
            'completedSections': <int>[], // section indices
            'lastSectionIndex': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        });

    return docRef.id;
  }

  /// Stream a user's plans, newest first.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPlans({
    required String uid,
    int limit = 50,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Fetch a single plan by ID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getPlanById({
    required String uid,
    required String lessonId,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(lessonId)
        .get();
  }

  // -------------------------
  // Progress helpers
  // -------------------------

  /// Returns the embedded progress map or null.
  Future<Map<String, dynamic>?> getProgress({
    required String uid,
    required String lessonId,
  }) async {
    final snap =
        await _db
            .collection('users')
            .doc(uid)
            .collection('lessonPlans')
            .doc(lessonId)
            .get();

    final data = snap.data() ?? <String, dynamic>{};
    final progress = data['progress'];
    return (progress is Map<String, dynamic>) ? progress : null;
  }

  /// Mark a section as completed / incomplete and set lastSectionIndex.
  Future<void> setSectionCompleted({
    required String uid,
    required String lessonId,
    required int sectionIndex,
    required bool completed,
  }) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(lessonId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = (snap.data() ?? <String, dynamic>{});
      final progress =
          (data['progress'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      final existing =
          (progress['completedSections'] as List?) ?? const <dynamic>[];
      final completedSet =
          existing.isEmpty
              ? <int>{}
              : existing
                  .map((e) => e is int ? e : int.tryParse('$e') ?? -1)
                  .where((e) => e >= 0)
                  .toSet();

      if (completed) {
        completedSet.add(sectionIndex);
      } else {
        completedSet.remove(sectionIndex);
      }

      final updatedProgress = <String, dynamic>{
        ...progress,
        'completedSections': completedSet.toList()..sort(),
        'lastSectionIndex': sectionIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      tx.update(ref, <String, dynamic>{
        'progress': updatedProgress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Update the last viewed/played section without toggling completion.
  Future<void> setLastSectionIndex({
    required String uid,
    required String lessonId,
    required int sectionIndex,
  }) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(lessonId);

    await ref.update({
      'progress.lastSectionIndex': sectionIndex,
      'progress.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get the most recent lesson plan for a user (by createdAt desc).
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> getLatestPlan({
    required String uid,
  }) async {
    final snap =
        await _db
            .collection('users')
            .doc(uid)
            .collection('lessonPlans')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  // -------------------------
  // Chat transcript helpers (safe to keep; unused by current 3 screens)
  // -------------------------

  /// Add a chat turn under: users/{uid}/lessonPlans/{lessonId}/sections/{index}/chatTurns/{autoId}
  Future<void> addChatTurn({
    required String uid,
    required String lessonId,
    required int sectionIndex,
    required String role, // 'user' | 'assistant'
    required String content,
  }) async {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(lessonId)
        .collection('sections')
        .doc(sectionIndex.toString())
        .collection('chatTurns');

    await col.add({
      'role': role,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream chat turns for a section, ordered by time.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamChatTurns({
    required String uid,
    required String lessonId,
    required int sectionIndex,
    int limit = 200,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('lessonPlans')
        .doc(lessonId)
        .collection('sections')
        .doc(sectionIndex.toString())
        .collection('chatTurns')
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs);
  }
}
