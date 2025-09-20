import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryRepository {
  final FirebaseFirestore _db;
  CategoryRepository(this._db);

  CollectionReference<Map<String, dynamic>> _catCol(
    String uid,
    String planId,
  ) => _db
      .collection('users')
      .doc(uid)
      .collection('lessonPlans')
      .doc(planId)
      .collection('categories');

  Stream<List<Category>> watch(String uid, String planId) {
    return _catCol(uid, planId)
        .orderBy('order', descending: false)
        .snapshots()
        .map(
          (q) =>
              q.docs
                  .map((d) => Category.fromFirestore(d.id, d.data()))
                  .toList(),
        );
  }

  Future<void> upsert(String uid, String planId, Category c) async {
    final ref = _catCol(uid, planId).doc(c.id);
    final exists = (await ref.get()).exists;

    final data = c.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (!exists) data['createdAt'] = FieldValue.serverTimestamp();

    await ref.set(data, SetOptions(merge: true));
  }
}
