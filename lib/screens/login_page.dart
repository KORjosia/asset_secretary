//asset_secretary\lib\screens\login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) {
      _snack('아이디/비밀번호를 입력해줘.');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = '$id@yourapp.com';
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pw);
      // ✅ AuthGate가 자동으로 다음 화면으로 이동시킴 (home or onboarding)
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _snack('아이디 또는 비밀번호가 올바르지 않아.');
      } else {
        _snack('로그인 실패: ${e.code}');
      }
    } catch (e) {
      _snack('로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? '로그인 중...' : '로그인'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage()));
              },
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
