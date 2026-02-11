//asset_secretary\lib\onboarding\goal_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'money_formatter.dart';
import '../services/firestore_service.dart';
import '../auth/auth_gate.dart';


enum GoalPageMode { onboarding, edit }

class GoalPage extends StatefulWidget {
  const GoalPage({super.key, required this.mode});
  final GoalPageMode mode;

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  static const bgTop = Color(0xFF0A1730);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);

  bool _loading = true;
  bool _saving = false;

  // 투자 성향 테스트(라디오)
  // Q1: 투자 위험 감내
  int? _q1; // 1(가장 안전) ~ 5(가장 공격)
  // Q2: 손실 대응
  int? _q2; // 1(최소 손실) ~ 5(추가매수)
  // Q3: 투자 기간(짧->길)
  int? _q3; // 1(6개월 이내) ~ 5(5년 이상)

  // 목표 설정
  final _amountCtrl = TextEditingController();   // 금액 목표
  final _estateCtrl = TextEditingController();   // 부동산 목표(자유 입력)

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _estateCtrl.dispose();
    super.dispose();
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _prefill() async {
    if (widget.mode == GoalPageMode.onboarding) {
      // 온보딩은 기본값 빈 상태로 시작
      if (mounted) setState(() => _loading = false);
      return;
    }

    // edit 모드일 때만 prefill(홈에서 목표 수정)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};
    final goal = (data['goal'] as Map<String, dynamic>?) ?? {};

    final type = (goal['type'] as String?) ?? 'amount';
    final ta = (goal['targetAmount'] as num?)?.toInt() ?? 0;

    if (ta > 0) {
      _amountCtrl.text = ThousandsFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: ta.toString()),
      ).text;
    }

    if (type == 'real_estate') {
      final building = (goal['buildingName'] as String?) ?? '';
      _estateCtrl.text = building;
    }

    // 저장된 값이 있으면 테스트값도 맞춰보기(없으면 null 유지)
    _q1 = (goal['quizQ1'] as int?);
    _q2 = (goal['quizQ2'] as int?);
    _q3 = (goal['quizQ3'] as int?);

    if (mounted) setState(() => _loading = false);
  }

  int _calcRiskLevel() {
    // 1~5로 반환
    final a = _q1 ?? 1;
    final b = _q2 ?? 1;
    final c = _q3 ?? 1;
    final avg = (a + b + c) / 3.0;
    final r = avg.round();
    return r.clamp(1, 5);
  }

  int _calcDurationMonths() {
    // Q3 기준으로 기간(개월) 매핑
    switch (_q3 ?? 1) {
      case 1:
        return 6;   // 6개월 이내
      case 2:
        return 12;  // 6개월~1년
      case 3:
        return 36;  // 1~3년
      case 4:
        return 60;  // 3~5년
      case 5:
      default:
        return 60;  // 5년 이상(상한 60 유지)
    }
  }

  bool get _canSubmit {
    final amount = parseMoney(_amountCtrl.text);
    final estate = _estateCtrl.text.trim();

    final hasGoal = amount > 0 || estate.isNotEmpty;
    final hasQuiz = _q1 != null && _q2 != null && _q3 != null;
    return hasGoal && hasQuiz;
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_canSubmit) {
      _snack('투자 성향 테스트 3개 + 목표 설정(금액 또는 부동산) 중 하나는 필수야.');
      return;
    }

    final amount = parseMoney(_amountCtrl.text);
    final estate = _estateCtrl.text.trim();

    final String type = estate.isNotEmpty ? 'real_estate' : 'amount';

    final risk = _calcRiskLevel();
    final months = _calcDurationMonths();

    setState(() => _saving = true);
    try {
      final goalPayload = <String, dynamic>{
        'type': type,
        'targetAmount': amount > 0 ? amount : 0,
        'riskLevel': risk,
        'durationMonths': months,
        'quizQ1': _q1,
        'quizQ2': _q2,
        'quizQ3': _q3,
        if (type == 'real_estate') 'buildingName': estate,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ 5/6 완료 후 mentor로
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'goal': goalPayload,
        if (widget.mode == GoalPageMode.onboarding) 'onboardingStep': 'mentor',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (widget.mode == GoalPageMode.onboarding) {
        // (선택) service도 쓰고 싶으면 유지 가능
        await FirestoreService.setOnboardingStep(user.uid, 'mentor');

        _snack('목표 설정 완료!');

        // ✅ 핵심: AuthGate로 스택 리셋 → AuthGate가 step=mentor 감지 → MentorPage 즉시 노출
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
        return;
      }

      // edit 모드면 그냥 저장 후 뒤로
      _snack('저장 완료!');
      if (widget.mode == GoalPageMode.edit && mounted) Navigator.pop(context);
    } catch (e) {
      _snack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


    Widget _topProgress() {
    if (widget.mode == GoalPageMode.edit) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('투자 성향 & 목표',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('5/6', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 5 / 6, // ✅ 0.8333...
              minHeight: 6,
              backgroundColor: Color(0x1FFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }


  Widget _radioLine({
    required int value,
    required int? group,
    required String label,
    required void Function(int) onChanged,
  }) {
    final selected = group == value;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: value,
              groupValue: group,
              onChanged: (v) => onChanged(v!),
              activeColor: accent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xCCFFFFFF),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _goalFieldDec(String label, {String? hint, Widget? prefix, Widget? suffix}) {
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
        borderSide: const BorderSide(color: accent),
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
    );
  }

  Widget _bottomButton() {
    final enabled = _canSubmit;

    return Positioned(
      left: 18,
      right: 18,
      bottom: 18,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: const Color(0xFF103A4D),
            disabledForegroundColor: const Color(0x66FFFFFF),
          ),
          onPressed: (_saving || !enabled) ? null : _submit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 18),
              const SizedBox(width: 8),
              Text(_saving ? '처리 중...' : (widget.mode == GoalPageMode.onboarding ? '가입 완료' : '저장'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == GoalPageMode.onboarding ? '회원가입' : '목표 수정';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: accent, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : AbsorbPointer(
                  absorbing: _saving,
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.only(top: 8),
                        children: [
                          _topProgress(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: _cardDeco,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '투자 성향 테스트',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  const SizedBox(height: 14),

                                  const Text(
                                    '1. 투자 성향이 어느 정도 되시나요?',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  _radioLine(
                                    value: 1,
                                    group: _q1,
                                    label: '투자 없이 안전한 예금입니다',
                                    onChanged: (v) => setState(() => _q1 = v),
                                  ),
                                  _radioLine(
                                    value: 2,
                                    group: _q1,
                                    label: '1년 미만의 투자 상품이 있습니다',
                                    onChanged: (v) => setState(() => _q1 = v),
                                  ),
                                  _radioLine(
                                    value: 3,
                                    group: _q1,
                                    label: '1~3년의 투자 경험이 있습니다',
                                    onChanged: (v) => setState(() => _q1 = v),
                                  ),
                                  _radioLine(
                                    value: 4,
                                    group: _q1,
                                    label: '3~5년의 투자 경험이 있습니다',
                                    onChanged: (v) => setState(() => _q1 = v),
                                  ),
                                  _radioLine(
                                    value: 5,
                                    group: _q1,
                                    label: '5년 이상의 투자 경험이 있습니다',
                                    onChanged: (v) => setState(() => _q1 = v),
                                  ),

                                  const SizedBox(height: 14),
                                  const Text(
                                    '2. 투자 손실이 발생하면 어떻게 하시겠습니까?',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  _radioLine(
                                    value: 1,
                                    group: _q2,
                                    label: '손실을 최소화하고 바로 매도',
                                    onChanged: (v) => setState(() => _q2 = v),
                                  ),
                                  _radioLine(
                                    value: 2,
                                    group: _q2,
                                    label: '일부 주식 상품을 유지하며 관망',
                                    onChanged: (v) => setState(() => _q2 = v),
                                  ),
                                  _radioLine(
                                    value: 3,
                                    group: _q2,
                                    label: '일부 포트폴리오를 정리하고 리밸런싱',
                                    onChanged: (v) => setState(() => _q2 = v),
                                  ),
                                  _radioLine(
                                    value: 4,
                                    group: _q2,
                                    label: '주가 추가 기회로 생각하고 일부 매수',
                                    onChanged: (v) => setState(() => _q2 = v),
                                  ),
                                  _radioLine(
                                    value: 5,
                                    group: _q2,
                                    label: '적극적으로 추가 매수',
                                    onChanged: (v) => setState(() => _q2 = v),
                                  ),

                                  const SizedBox(height: 14),
                                  const Text(
                                    '3. 투자 기간은 어느 정도를 생각하십니까?',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  _radioLine(
                                    value: 1,
                                    group: _q3,
                                    label: '6개월 이내',
                                    onChanged: (v) => setState(() => _q3 = v),
                                  ),
                                  _radioLine(
                                    value: 2,
                                    group: _q3,
                                    label: '6개월 ~ 1년',
                                    onChanged: (v) => setState(() => _q3 = v),
                                  ),
                                  _radioLine(
                                    value: 3,
                                    group: _q3,
                                    label: '1년 ~ 3년',
                                    onChanged: (v) => setState(() => _q3 = v),
                                  ),
                                  _radioLine(
                                    value: 4,
                                    group: _q3,
                                    label: '3년 ~ 5년',
                                    onChanged: (v) => setState(() => _q3 = v),
                                  ),
                                  _radioLine(
                                    value: 5,
                                    group: _q3,
                                    label: '5년 이상 장기 투자',
                                    onChanged: (v) => setState(() => _q3 = v),
                                  ),

                                  const SizedBox(height: 18),

                                  // 목표 설정 섹션
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0x0AFFFFFF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0x22FFFFFF)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.flag_outlined, color: accent, size: 18),
                                            SizedBox(width: 10),
                                            Text(
                                              '목표 설정',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          '목표 금액/부동산 중 하나는 선택해야 합니다 (선택사항)',
                                          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                                        ),
                                        const SizedBox(height: 12),

                                        TextField(
                                          controller: _amountCtrl,
                                          style: const TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
                                          decoration: _goalFieldDec(
                                            '금액 목표 (선택사항)',
                                            hint: '1,000,000',
                                            prefix: const Icon(Icons.attach_money, color: Color(0xFF3EDC85), size: 20),
                                            suffix: const Padding(
                                              padding: EdgeInsets.only(top: 12),
                                              child: Text('₩', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                          textAlign: TextAlign.right,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        const SizedBox(height: 12),

                                        TextField(
                                          controller: _estateCtrl,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: _goalFieldDec(
                                            '부동산 목표 (선택사항)',
                                            hint: '예. 서울 강남구 아파트',
                                            prefix: const Icon(Icons.home_outlined, color: Color(0xFF7CC7FF), size: 20),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      _bottomButton(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
