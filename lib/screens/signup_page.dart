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
  final _idCtrl = TextEditingController(); // UI에선 이메일처럼 보이지만 실제론 id로 사용
  final _nickCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  DateTime? _birth;

  bool _loading = false;
  bool _pwVisible = false;
  bool _pw2Visible = false;
  bool _agree = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _nickCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
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

  String get _birthText {
    if (_birth == null) return '생년월일 선택';
    final y = _birth!.year;
    final m = _birth!.month.toString().padLeft(2, '0');
    final d = _birth!.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  bool get _canNext {
    final name = _nameCtrl.text.trim();
    final id = _idCtrl.text.trim();
    final nick = _nickCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pw2 = _pw2Ctrl.text;
    return _agree && name.isNotEmpty && id.isNotEmpty && nick.isNotEmpty && pw.length >= 6 && pw == pw2 && _birth != null;
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final id = _idCtrl.text.trim();
    final nick = _nickCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pw2 = _pw2Ctrl.text;

    if (!_agree) {
      _snack('이용약관에 동의해줘.');
      return;
    }
    if (name.isEmpty || id.isEmpty || nick.isEmpty || pw.isEmpty || pw2.isEmpty || _birth == null) {
      _snack('모든 항목을 입력/선택해줘.');
      return;
    }
    if (pw.length < 6) {
      _snack('비밀번호는 6자 이상이야.');
      return;
    }
    if (pw != pw2) {
      _snack('비밀번호가 일치하지 않아.');
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
          'onboardingStep': 'info',
        });

        tx.set(usernameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
        tx.set(nicknameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      });

      _snack('회원가입 완료!');
      if (mounted) Navigator.pop(context); // AuthGate가 자동으로 info로 보냄
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.account_balance_wallet_rounded, color: accent, size: 18),
            SizedBox(width: 8),
            Text('회원가입', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text('1/5', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            children: [
              const SizedBox(height: 6),

              // step label + progress bar (상단 느낌)
              const Text('기본 정보', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.20,
                  minHeight: 6,
                  backgroundColor: Color(0x1FFFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),

              const SizedBox(height: 14),

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
                    const Text('기본 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('이름', hint: '나스'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _idCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec('아이디', hint: '특수문자 불가'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nickCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('닉네임', hint: 'naeuninvestor'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _pwCtrl,
                      style: const TextStyle(color: Colors.white),
                      obscureText: !_pwVisible,
                      decoration: _dec(
                        '비밀번호',
                        hint: '최소 6자리',
                        suffix: IconButton(
                          onPressed: () => setState(() => _pwVisible = !_pwVisible),
                          icon: Icon(_pwVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0x99FFFFFF), size: 20),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _pw2Ctrl,
                      style: const TextStyle(color: Colors.white),
                      obscureText: !_pw2Visible,
                      decoration: _dec(
                        '비밀번호 확인',
                        hint: '••••••••',
                        suffix: IconButton(
                          onPressed: () => setState(() => _pw2Visible = !_pw2Visible),
                          icon: Icon(_pw2Visible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0x99FFFFFF), size: 20),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // birth (필수 요구사항이라 추가)
                    InkWell(
                      onTap: _pickBirth,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            const Text('생년월일', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                            const Spacer(),
                            Text(_birthText, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                            const SizedBox(width: 6),
                            const Icon(Icons.calendar_month, color: Color(0x99FFFFFF), size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: _agree,
                          onChanged: (v) => setState(() => _agree = v ?? false),
                          activeColor: accent,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Color(0x66FFFFFF)),
                        ),
                        const Expanded(
                          child: Text(
                            '이용약관 및 개인정보처리방침에 동의합니다',
                            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          disabledBackgroundColor: const Color(0xFF103A4D),
                          disabledForegroundColor: const Color(0x66FFFFFF),
                        ),
                        onPressed: _loading
                            ? null
                            : (_canNext ? _signup : null),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_loading ? '처리 중...' : '다음',
                                style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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
