//asset_secretary\lib\services\firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> ensureUserDoc(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'onboardingStep': 'info',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setOnboardingStep(String uid, String step) async {
    await _db.collection('users').doc(uid).set({
      'onboardingStep': step,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
