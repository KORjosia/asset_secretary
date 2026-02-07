//asset_secretary\lib\screens\signup_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  DateTime? _birth;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    final nick = _nickCtrl.text.trim();

    if (name.isEmpty || id.isEmpty || pw.isEmpty || nick.isEmpty || _birth == null) {
      _snack('모든 항목을 입력/선택해줘.');
      return;
    }
    if (pw.length < 6) {
      _snack('비밀번호는 6자 이상이야.');
      return;
    }

    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final email = '$id@yourapp.com';
    UserCredential? cred;

    try {
      // ✅ Auth 먼저 생성
      cred = await auth.createUserWithEmailAndPassword(email: email, password: pw);
      final uid = cred.user!.uid;

      // ✅ 트랜잭션: 아이디/닉네임 중복 + 유저 문서 생성 + 인덱스 문서 생성
      await db.runTransaction((tx) async {
        final usernameRef = db.collection('usernames').doc(id);
        final nicknameRef = db.collection('nicknames').doc(nick);
        final userRef = db.collection('users').doc(uid);

        final usernameSnap = await tx.get(usernameRef);
        if (usernameSnap.exists) throw Exception('DUP_USERNAME');

        final nicknameSnap = await tx.get(nicknameRef);
        if (nicknameSnap.exists) throw Exception('DUP_NICKNAME');

        tx.set(userRef, {
          'name': name,
          'username': id,
          'nickname': nick,
          'birth': Timestamp.fromDate(_birth!),
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingStep': 'info', // ✅ 신규는 정보입력부터
        });

        tx.set(usernameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
        tx.set(nicknameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      });

      _snack('회원가입 완료!');
      if (mounted) Navigator.pop(context); // 로그인 화면으로 돌아가도, AuthGate가 바로 온보딩으로 보냄
    } catch (e) {
      // 중복/실패면 방금 만든 Auth 계정 삭제 (아이디 재시도 가능)
      try {
        await cred?.user?.delete();
      } catch (_) {}

      final msg = e.toString();
      if (msg.contains('DUP_USERNAME')) {
        _snack('이미 사용 중인 아이디야.');
      } else if (msg.contains('DUP_NICKNAME')) {
        _snack('이미 사용 중인 닉네임이야.');
      } else if (e is FirebaseAuthException) {
        _snack('회원가입 실패: ${e.code}');
      } else {
        _snack('회원가입 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String get _birthText {
    if (_birth == null) return '생년월일 선택';
    return '${_birth!.year}.${_birth!.month.toString().padLeft(2, '0')}.${_birth!.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '이름')),
            const SizedBox(height: 12),
            TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: '아이디(중복불가)')),
            const SizedBox(height: 12),
            TextField(controller: _pwCtrl, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호')),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('생년월일'),
              subtitle: Text(_birthText),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickBirth,
            ),
            const SizedBox(height: 12),
            TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: '닉네임(중복불가)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                child: Text(_loading ? '가입 중...' : '가입하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
