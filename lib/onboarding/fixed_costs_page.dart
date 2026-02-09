//asset_secretary\lib\onboarding\fixed_costs_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'goal_page.dart';
import 'money_formatter.dart';
import '../services/firestore_service.dart';

class FixedCostsPage extends StatefulWidget {
  const FixedCostsPage({
    super.key,
    required this.age,
    required this.job,
    required this.region,
    required this.mainIncome,
    required this.subIncome,
    required this.selectedAssets,
    required this.selectedAssetsMoney, // ✅ 추가
  });

  final int age;
  final String job;
  final String region;
  final int mainIncome;
  final int subIncome;

  final List<String> selectedAssets; // 3/5 선택값
  final Map<String, int> selectedAssetsMoney; // ✅ 3/5 금액

  @override
  State<FixedCostsPage> createState() => _FixedCostsPageState();
}

class _FixedCostsPageState extends State<FixedCostsPage> {
  static const bgTop = Color(0xFF0A1730);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);

  bool _saving = false;

  static const fixedCostItems = [
    '월세',
    '관리비',
    '휴대폰',
    '교통비',
    '여가비',
    '보험료',
    '대출이자',
    '교육비',
    '자기계발',
    '기타',
  ];

  final Set<String> _selectedFixed = {};
  late final Map<String, TextEditingController> _fixedCtrls = {
    for (final k in fixedCostItems) k: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _fixedCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      );

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _moneyBox(TextEditingController ctrl) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
          filled: true,
          fillColor: const Color(0x1AFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent),
          ),
          suffixText: '원',
          suffixStyle: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Future<void> _saveAndNext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      // ✅ 3/5에서 받은 자산 금액
      final managementTools = <String, int>{
        for (final k in widget.selectedAssets) k: widget.selectedAssetsMoney[k] ?? 0,
      };

      // ✅ 4/5에서 입력한 고정지출 금액
      final fixedCosts = <String, int>{
        for (final k in _selectedFixed) k: parseMoney(_fixedCtrls[k]!.text),
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profile': {
          'age': widget.age,
          'job': widget.job,
          'region': widget.region,
          'mainIncome': widget.mainIncome,
          'subIncome': widget.subIncome,
          'managementTools': managementTools,
          'fixedCosts': fixedCosts,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'onboardingStep': 'goal',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirestoreService.setOnboardingStep(user.uid, 'goal');

      if (!mounted) return;

      // ✅ 보험: AuthGate 스트림 반응이 늦어도 무조건 5/5로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GoalPage(mode: GoalPageMode.onboarding)),
      );
    } catch (e) {
      _snack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _topProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('고정 지출', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('4/5', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.80,
              minHeight: 6,
              backgroundColor: Color(0x1FFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label) {
    final checked = _selectedFixed.contains(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (checked) {
              _selectedFixed.remove(label);
              _fixedCtrls[label]!.text = '';
            } else {
              _selectedFixed.add(label);
            }
          });
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Checkbox(
                value: checked,
                onChanged: (_) {
                  setState(() {
                    if (checked) {
                      _selectedFixed.remove(label);
                      _fixedCtrls[label]!.text = '';
                    } else {
                      _selectedFixed.add(label);
                    }
                  });
                },
                activeColor: accent,
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0x66FFFFFF)),
              ),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (checked) _moneyBox(_fixedCtrls[label]!),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton() {
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
          onPressed: _saving ? null : _saveAndNext,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_saving ? '저장 중...' : '다음', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom]),
        ),
        child: SafeArea(
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
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: accent, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('고정 지출',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '현재 고정 지출을 선택하고 금액을 입력해주세요 (선택사항)',
                            style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          ...fixedCostItems.map(_tile),
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
    );
  }
} 
