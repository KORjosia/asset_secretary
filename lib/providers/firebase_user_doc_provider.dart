//lib/providers/firebase_user_doc_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/auth_providers.dart';

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

final userDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    return doc.data();
  });
});

/// ✅ 홈에서 바로 쓰기 편한 "닉네임 전용" Provider
final nicknameProvider = Provider<String>((ref) {
  final docAsync = ref.watch(userDocProvider);
  return docAsync.maybeWhen(
    data: (doc) => (doc?['nickname'] as String?)?.trim() ?? '',
    orElse: () => '',
  );
});
