import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class CategoryChatRepository {
  final FirebaseFirestore _db;
  CategoryChatRepository(this._db);

  CollectionReference<Map<String, dynamic>> _catCol(
    String uid,
    String planId,
  ) => _db
      .collection('users')
      .doc(uid)
      .collection('lessonPlans')
      .doc(planId)
      .collection('categories');

  DocumentReference<Map<String, dynamic>> _catDoc(
    String uid,
    String planId,
    String categoryId,
  ) => _catCol(uid, planId).doc(categoryId);

  CollectionReference<Map<String, dynamic>> _sessionCol(
    String uid,
    String planId,
    String categoryId,
  ) => _catDoc(uid, planId, categoryId).collection('sessions');

  DocumentReference<Map<String, dynamic>> _sessionDoc(
    String uid,
    String planId,
    String categoryId,
    String sessionId,
  ) => _sessionCol(uid, planId, categoryId).doc(sessionId);

  CollectionReference<Map<String, dynamic>> _msgsCol(
    String uid,
    String planId,
    String categoryId,
    String sessionId,
  ) => _sessionDoc(uid, planId, categoryId, sessionId).collection('messages');

  /// Ensure an active session exists; return its id.
  Future<String> ensureActiveSession(
    String uid,
    String planId,
    String categoryId,
  ) async {
    final catRef = _catDoc(uid, planId, categoryId);
    final catSnap = await catRef.get();
    String? activeId = catSnap.data()?['activeSessionId'] as String?;
    if (activeId != null && activeId.isNotEmpty) {
      final s = await _sessionDoc(uid, planId, categoryId, activeId).get();
      if (s.exists && (s.data()?['isActive'] == true)) return activeId;
    }

    final newRef = _sessionCol(uid, planId, categoryId).doc();
    await newRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'messageCount': 0,
    });
    await catRef.set({'activeSessionId': newRef.id}, SetOptions(merge: true));
    return newRef.id;
  }

  Future<void> appendMessage(
    String uid,
    String planId,
    String categoryId,
    String sessionId,
    ChatMessage m,
  ) async {
    final batch = _db.batch();

    batch.set(_msgsCol(uid, planId, categoryId, sessionId).doc(), {
      'role': m.role,
      'text': m.text,
      'at': FieldValue.serverTimestamp(),
    });

    batch.update(_sessionDoc(uid, planId, categoryId, sessionId), {
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<List<ChatMessage>> watchMessages(
    String uid,
    String planId,
    String categoryId,
    String sessionId, {
    int limit = 200,
  }) {
    return _msgsCol(uid, planId, categoryId, sessionId)
        .orderBy('at', descending: false)
        .limit(limit)
        .snapshots()
        .map(
          (q) =>
              q.docs.map((d) => ChatMessage.fromFirestore(d.data())).toList(),
        );
  }

  Future<List<ChatMessage>> recentMessages(
    String uid,
    String planId,
    String categoryId, {
    int limit = 25,
  }) async {
    final catSnap = await _catDoc(uid, planId, categoryId).get();
    final activeId = catSnap.data()?['activeSessionId'] as String?;
    if (activeId == null || activeId.isEmpty) return [];
    final q =
        await _msgsCol(
          uid,
          planId,
          categoryId,
          activeId,
        ).orderBy('at', descending: true).limit(limit).get();
    final list =
        q.docs.map((d) => ChatMessage.fromFirestore(d.data())).toList();
    return list.reversed.toList();
  }
}
