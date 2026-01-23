import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_providers.dart';
import 'signup_service.dart';

final signUpServiceProvider = Provider<SignUpService>((ref) {
  return SignUpService(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
  );
});



class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final nickCtrl = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailCtrl.dispose();
    pwCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = emailCtrl.text.trim();
    final pw = pwCtrl.text; // 비번은 trim 비추
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final nick = nickCtrl.text.trim();

    // 프론트 validation
    if (email.isEmpty || !email.contains('@')) {
      setState(() => error = '이메일을 올바르게 입력해줘.');
      return;
    }
    if (pw.length < 8) {
      setState(() => error = '비밀번호는 8자리 이상이어야 해.');
      return;
    }
    if (name.isEmpty) {
      setState(() => error = '이름을 입력해줘.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => error = '전화번호를 입력해줘.');
      return;
    }
    if (nick.isEmpty) {
      setState(() => error = '닉네임을 입력해줘.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ref.read(signUpServiceProvider).signUp(
            email: email,
            password: pw,
            name: name,
            phone: phone,
            nickname: nick,
          );

      if (mounted) Navigator.pop(context); // 가입 후 로그인 화면으로
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.code == 'email-already-in-use'
          ? '이미 사용 중인 이메일이야.'
          : (e.message ?? '회원가입 실패(${e.code})'));
    } on StateError catch (e) {
      setState(() => error = e.message); // 이름/닉네임 중복 메시지
    } catch (e) {
      setState(() => error = '회원가입 실패: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: '이메일')),
            const SizedBox(height: 8),
            TextField(controller: pwCtrl, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호(8자리 이상)')),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '이름(중복 불가)')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: '전화번호')),
            const SizedBox(height: 8),
            TextField(controller: nickCtrl, decoration: const InputDecoration(labelText: '닉네임(중복 불가)')),
            const SizedBox(height: 12),
            if (error != null) ...[
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: loading ? null : _signup,
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
