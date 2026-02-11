//asset_secretary\lib\onboarding\consult_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../services/firestore_service.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  // theme
  static const bgTop = Color(0xFF0A1730);
  static const bgMid = Color(0xFF0B1833);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);
  static const warn = Color(0xFFFFD54A);
  static const ok = Color(0xFF3EDC85);

  bool _loading = true;
  bool _sending = false;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _goal;
  String? _mentorName;
  String? _mentorId;

  final _subjectCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  static const int _maxChars = 300;
  static const int _costCoins = 10; // UI용 (실제 차감 로직은 추후)

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};

    _profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    _goal = (data['goal'] as Map<String, dynamic>?) ?? {};

    final selected = (data['selectedMentor'] as Map<String, dynamic>?) ?? {};
    _mentorName = (selected['name'] as String?) ?? '';
    _mentorId = (selected['id'] as String?) ?? '';

    if (mounted) setState(() => _loading = false);
  }

  // ---------- helpers ----------
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _money(dynamic v) {
    final n = (v is int) ? v : (v is num ? v.toInt() : 0);
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '₩${buf.toString()}';
  }

  int _sumMap(dynamic m) {
    if (m is! Map) return 0;
    var sum = 0;
    for (final v in m.values) {
      if (v is int) sum += v;
      if (v is num) sum += v.toInt();
    }
    return sum;
  }

  String _riskLabel(dynamic risk) {
    final r = (risk is int) ? risk : (risk is num ? risk.toInt() : 1);
    switch (r) {
      case 1:
        return '안전';
      case 2:
        return '보수';
      case 3:
        return '중립';
      case 4:
        return '공격';
      case 5:
      default:
        return '고위험';
    }
  }

  // ---------- dialogs ----------
  Future<bool> _confirmDialog(String mentor) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0B162C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('상담 신청 확인',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.monetization_on_rounded, color: warn),
                      SizedBox(width: 8),
                      Text('10', style: TextStyle(color: warn, fontWeight: FontWeight.w900, fontSize: 22)),
                      SizedBox(width: 6),
                      Text('코인', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$mentor 전문가에게\n상담 신청하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.35, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xCCFFFFFF),
                          side: const BorderSide(color: Color(0x33FFFFFF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('신청하기', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return ok ?? false;
  }

  Future<void> _successDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0B162C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ok, Color(0xFF1DBF73)]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 12),
                const Text('신청이 완료되었습니다',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                const Text(
                  '답변에는 1~3일이 소요됩니다.\n답변이 도착하면 알림을 보내드리겠습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xB3FFFFFF), height: 1.35, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- actions ----------
  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mentor = (_mentorName ?? '').trim();
    if (mentor.isEmpty) {
      _snack('멘토가 선택되지 않았어. 멘토찾기 단계로 돌아가줘.');
      return;
    }

    final subject = _subjectCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    if (subject.isEmpty || msg.isEmpty) {
      _snack('제목/문의 내용을 입력해줘.');
      return;
    }
    if (msg.length > _maxChars) {
      _snack('문의 내용은 $_maxChars자 이하여야 해.');
      return;
    }

    final ok = await _confirmDialog(mentor);
    if (!ok) return;

    final mentorId = (_mentorId ?? '').trim();

    setState(() => _sending = true);
    try {
      final reqRef = FirebaseFirestore.instance.collection('consult_requests').doc();

      await reqRef.set({
        'uid': user.uid,
        'mentorName': mentor,
        'mentorId': mentorId.isNotEmpty ? mentorId : mentor,
        'schemaVersion': 2,
        'userProfileSnapshot': _profile ?? {},
        'goalSnapshot': _goal ?? {},
        'fixedCostsSnapshot': (_profile ?? {})['fixedCosts'] ?? {}, // ✅ 추가 저장
        'subject': subject, // ✅ 추가
        'question': msg,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'requested',
        'costCoins': _costCoins,
      });

      // ✅ 온보딩 종료 → 홈
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingStep': 'done',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirestoreService.setOnboardingStep(user.uid, 'done');

      await _successDialog();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      _snack('요청 실패: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---------- UI helpers ----------
  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
      filled: true,
      fillColor: const Color(0x1AFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent),
      ),
    );
  }

  Widget _chip(String text, {Color? border, Color? textColor, Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border ?? const Color(0x22FFFFFF)),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
      ),
    );
  }

  Widget _sectionTitle(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required Color iconColor, required String title, required String sub, Color? borderColor, Color? bg}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg ?? const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Color(0xB3FFFFFF), fontWeight: FontWeight.w700, fontSize: 11, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile ?? {};
    final goal = _goal ?? {};

    final mentor = (_mentorName ?? '').trim();
    final job = (profile['job'] ?? '').toString();
    final region = (profile['region'] ?? '').toString();
    final age = (profile['age'] ?? 0).toString();

    final mainIncome = (profile['mainIncome'] ?? 0);
    final subIncome = (profile['subIncome'] ?? 0);

    final fixedCosts = (profile['fixedCosts'] as Map<String, dynamic>?) ?? {};
    final fixedSum = _sumMap(fixedCosts);

    final goalType = (goal['type'] as String?) ?? 'amount';
    final riskLevel = goal['riskLevel'] ?? 1;
    final months = goal['durationMonths'] ?? 12;

    final targetAmount = goal['targetAmount'] ?? 0;
    final buildingName = (goal['buildingName'] ?? '').toString();

    final msgLen = _msgCtrl.text.length;

    return WillPopScope(
      onWillPop: () async {
        // ✅ 뒤로가기 활성화: consult -> mentor로 복귀
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'onboardingStep': 'mentor',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await FirestoreService.setOnboardingStep(user.uid, 'mentor');
        }

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('상담 문의', style: TextStyle(fontWeight: FontWeight.w900)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              // ✅ 뒤로가기 버튼 활성화
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'onboardingStep': 'mentor',
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                await FirestoreService.setOnboardingStep(user.uid, 'mentor');
              }

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: warn, size: 16),
                  SizedBox(width: 6),
                  Text('0', // ✅ 코인 연동은 추후, 일단 UI만
                      style: TextStyle(color: warn, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgMid, bgBottom],
            ),
          ),
          child: SafeArea(
            child: AbsorbPointer(
              absorbing: _sending,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                children: [
                  // Expert Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accent, width: 2),
                            color: const Color(0xFF0B2F45),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            mentor.isEmpty ? 'ME' : mentor.substring(0, 1),
                            style: const TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mentor.isEmpty ? '멘토' : mentor,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              _chip('선택된 전문가', border: const Color(0x330AA3E3), textColor: accent, bg: const Color(0x1A0AA3E3)),
                              const SizedBox(height: 6),
                              const Text('상담은 1~3일 내 답변이 도착합니다',
                                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cost info
                  _infoCard(
                    icon: Icons.monetization_on_rounded,
                    iconColor: warn,
                    title: '상담 비용',
                    sub: '1회 상담 $_costCoins 코인이 차감됩니다 (데모: 차감 로직은 추후 연결)',
                    borderColor: const Color(0x33FFD54A),
                    bg: const Color(0x14FFD54A),
                  ),

                  const SizedBox(height: 14),

                  // Shared Info
                  _sectionTitle('전문가에게 공유되는 정보', '더 정확한 상담을 위해 아래 정보가 전문가에게 전달됩니다'),

                  // Basic info
                  _block(
                    icon: Icons.person_rounded,
                    iconColor: accent,
                    title: '기본 정보',
                    child: Column(
                      children: [
                        _kv2('나이', '$age세'),
                        _kv2('직업', job),
                        _kv2('지역', region),
                        _kv2('투자성향', _riskLabel(riskLevel)),
                      ],
                    ),
                  ),

                  // Income
                  _block(
                    icon: Icons.attach_money_rounded,
                    iconColor: ok,
                    title: '수입 정보',
                    child: Column(
                      children: [
                        _kv2('주 수익', _money(mainIncome)),
                        _kv2('부 수익', _money(subIncome)),
                      ],
                    ),
                  ),

                  // ✅ 고정 지출 (요청사항: 목표 위에 추가)
                  _block(
                    icon: Icons.receipt_long_rounded,
                    iconColor: warn,
                    title: '고정 지출',
                    child: fixedCosts.isEmpty
                        ? const Text('선택한 고정 지출이 없습니다', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12))
                        : Column(
                            children: [
                              _kv2('총 고정지출', _money(fixedSum)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: fixedCosts.keys
                                    .map((k) => _chip(k, border: const Color(0x33FFFFFF), textColor: Colors.white, bg: const Color(0x1AFFFFFF)))
                                    .toList(),
                              ),
                            ],
                          ),
                  ),

                  // Goals
                  _block(
                    icon: Icons.flag_rounded,
                    iconColor: accent,
                    title: '설정한 목표',
                    child: Column(
                      children: [
                        _kv2('목표 타입', goalType == 'real_estate' ? '부동산 목표' : '금액 목표'),
                        if (goalType == 'real_estate')
                          _kv2('부동산', buildingName.isEmpty ? '-' : buildingName),
                        _kv2('목표금액', _money(targetAmount)),
                        _kv2('희망기간', '${months}개월'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Form
                  _sectionTitle('상담 작성', '제목과 문의 내용을 작성해 주세요'),

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
                          controller: _subjectCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('제목', hint: '상담 제목을 입력하세요'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('문의 내용', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w900, fontSize: 12)),
                            const Spacer(),
                            Text(
                              '$msgLen/$_maxChars',
                              style: TextStyle(
                                color: msgLen > _maxChars ? const Color(0xFFFF6B6B) : const Color(0x99FFFFFF),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _msgCtrl,
                          maxLines: 8,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec(
                            '내용',
                            hint: '상담받고 싶은 내용을 자세히 작성해주세요\n\n예시:\n- 현재 상황\n- 목표\n- 궁금한 점',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (msgLen > _maxChars)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('최대 300자까지 입력 가능합니다', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: (_sending ||
                                    _subjectCtrl.text.trim().isEmpty ||
                                    _msgCtrl.text.trim().isEmpty ||
                                    _msgCtrl.text.trim().length > _maxChars)
                                ? null
                                : _send,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: Text(_sending ? '요청 중...' : '상담 신청하기',
                                style: const TextStyle(fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor: const Color(0xFF103A4D),
                              disabledForegroundColor: const Color(0x66FFFFFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Guidelines
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('상담 안내', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        SizedBox(height: 8),
                        _Guide('전문가 답변까지 1~3일이 소요됩니다'),
                        _Guide('구체적으로 작성할수록 더 나은 답변을 받을 수 있습니다'),
                        _Guide('답변은 마이페이지에서 확인할 수 있습니다'),
                        _Guide('코인은 상담 신청 즉시 차감됩니다'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _block({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _kv2(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700, fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
        ],
      ),
    );
  }
}

class _Guide extends StatelessWidget {
  const _Guide(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w900)),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700, fontSize: 11, height: 1.35))),
        ],
      ),
    );
  }
}
