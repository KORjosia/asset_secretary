import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _norm(String s) => s.trim().toLowerCase();

class SignUpService {
  SignUpService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String nickname,
  }) async {
    if (password.length < 8) {
      throw StateError('비밀번호는 8자리 이상이어야 해.');
    }

    // 1) 이메일 중복은 Auth가 자동으로 막음
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    final nameKey = _norm(name);
    final nickKey = _norm(nickname);

    try {
      // 2) Firestore에서 이름/닉네임 “예약” + users 생성 (원자적으로)
      await _db.runTransaction((tx) async {
        final nameRef = _db.collection('unique_names').doc(nameKey);
        final nickRef = _db.collection('unique_nicknames').doc(nickKey);
        final userRef = _db.collection('users').doc(uid);

        final nameSnap = await tx.get(nameRef);
        if (nameSnap.exists) throw StateError('이미 사용 중인 이름이야.');

        final nickSnap = await tx.get(nickRef);
        if (nickSnap.exists) throw StateError('이미 사용 중인 닉네임이야.');

        tx.set(nameRef, {
          'uid': uid,
          'value': name.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(nickRef, {
          'uid': uid,
          'value': nickname.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(userRef, {
          'email': email.trim(),
          'name': name.trim(),
          'nickname': nickname.trim(),
          'phone': phone.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // 트랜잭션 실패하면 Auth 계정도 삭제해서 깔끔하게 롤백
      try {
        await cred.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }
}
