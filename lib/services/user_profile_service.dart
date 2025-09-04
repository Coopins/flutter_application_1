import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Create or update a Firestore profile doc at users/{uid}
  static Future<void> createOrUpdateProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Not signed in');

    if (displayName != null && displayName.trim().isNotEmpty) {
      await u.updateDisplayName(displayName.trim());
    }

    final docRef = _db.collection('users').doc(u.uid);
    await docRef.set({
      'email': u.email,
      'displayName': displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : u.displayName,
      'phoneNumber':
          phoneNumber?.trim().isNotEmpty == true ? phoneNumber!.trim() : null,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), // merge will keep existing
    }, SetOptions(merge: true));
  }
}
