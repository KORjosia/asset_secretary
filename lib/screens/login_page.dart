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
  bool _pwVisible = false;

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
      _snack('이메일/비밀번호를 입력해줘.');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = '$id@yourapp.com';
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pw);
      // ✅ AuthGate가 자동 분기
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

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
      filled: true,
      fillColor: const Color(0x1AFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0AA3E3)),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF0A1730);
    const bgBottom = Color(0xFF070F1F);
    const accent = Color(0xFF0AA3E3);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('로그인', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              const SizedBox(height: 10),

              // top icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 10),
                        color: Color(0x330AA3E3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 30),
                ),
              ),

              const SizedBox(height: 14),
              const Center(
                child: Text(
                  '환영합니다',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'ASS앱 로그인하여 자산을 관리하세요',
                  style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                ),
              ),

              const SizedBox(height: 18),

              // card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _idCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec('이메일', hint: 'example@email.com'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pwCtrl,
                      style: const TextStyle(color: Colors.white),
                      obscureText: !_pwVisible,
                      decoration: _dec(
                        '비밀번호',
                        hint: '••••••••',
                        suffix: IconButton(
                          onPressed: () => setState(() => _pwVisible = !_pwVisible),
                          icon: Icon(_pwVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0x99FFFFFF), size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _snack('비밀번호 찾기는 추후 연결 예정이야.');
                        },
                        child: const Text(
                          '비밀번호를 잊으셨나요?',
                          style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _login,
                        child: Text(_loading ? '로그인 중...' : '로그인',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('계정이 없으신가요? ', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // info banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFF0AA3E3), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '데모용: 회원은 자동으로 로그인되며 이후 이메일과\nID가 연동될 예정입니다.',
                        style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
