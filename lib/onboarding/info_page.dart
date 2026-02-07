//asset_secretary\lib\onboarding\info_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'money_formatter.dart';
import '../services/firestore_service.dart';

enum InfoPageMode { onboarding, edit }

class InfoPage extends StatefulWidget {
  const InfoPage({super.key, required this.mode});
  final InfoPageMode mode;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _mainIncomeCtrl = TextEditingController();
  final _subIncomeCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  bool _saving = false;
  bool _loading = true;

  static const managementItems = [
    '달러','금','ELS','채권','가상화폐','펀드','예금','적금','주식','부동산','기타'
  ];
  static const fixedCostItems = [
    '월세','대출이자','관리비','휴대폰','교통비','여가비','보험료','교육비','자기계발','기타'
  ];

  final Map<String, TextEditingController> _managementCtrls = {
    for (final k in managementItems) k: TextEditingController()
  };
  final Map<String, TextEditingController> _fixedCtrls = {
    for (final k in fixedCostItems) k: TextEditingController()
  };

  final Set<String> _selectedManagement = {};
  final Set<String> _selectedFixed = {};

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data();
    final profile = (data?['profile'] as Map<String, dynamic>?) ?? {};

    _mainIncomeCtrl.text = _fmt(profile['mainIncome']);
    _subIncomeCtrl.text = _fmt(profile['subIncome']);
    _jobCtrl.text = (profile['job'] as String?) ?? '';
    _regionCtrl.text = (profile['region'] as String?) ?? '';

    final tools = (profile['managementTools'] as Map<String, dynamic>?) ?? {};
    for (final entry in tools.entries) {
      _selectedManagement.add(entry.key);
      _managementCtrls[entry.key]?.text = _fmt(entry.value);
    }

    final costs = (profile['fixedCosts'] as Map<String, dynamic>?) ?? {};
    for (final entry in costs.entries) {
      _selectedFixed.add(entry.key);
      _fixedCtrls[entry.key]?.text = _fmt(entry.value);
    }

    if (mounted) setState(() => _loading = false);
  }

  String _fmt(dynamic v) {
    final n = (v is int) ? v : (v is num ? v.toInt() : 0);
    if (n <= 0) return '';
    // ThousandsFormatter는 입력용이라 여기선 간단 변환
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _mainIncomeCtrl.dispose();
    _subIncomeCtrl.dispose();
    _jobCtrl.dispose();
    _regionCtrl.dispose();
    for (final c in _managementCtrls.values) c.dispose();
    for (final c in _fixedCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mainIncome = parseMoney(_mainIncomeCtrl.text);
    final subIncome = parseMoney(_subIncomeCtrl.text);
    final job = _jobCtrl.text.trim();
    final region = _regionCtrl.text.trim();

    if (mainIncome <= 0 || job.isEmpty || region.isEmpty) {
      _snack('주수익/직업/지역은 필수야.');
      return;
    }

    final management = <String, int>{};
    for (final k in _selectedManagement) {
      management[k] = parseMoney(_managementCtrls[k]!.text);
    }

    final fixedCosts = <String, int>{};
    for (final k in _selectedFixed) {
      fixedCosts[k] = parseMoney(_fixedCtrls[k]!.text);
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profile': {
          'mainIncome': mainIncome,
          'subIncome': subIncome,
          'job': job,
          'region': region,
          'managementTools': management,
          'fixedCosts': fixedCosts,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        if (widget.mode == InfoPageMode.onboarding) 'onboardingStep': 'goal',
      }, SetOptions(merge: true));

      if (widget.mode == InfoPageMode.onboarding) {
        await FirestoreService.setOnboardingStep(user.uid, 'goal');
      }

      _snack('저장 완료!');
      if (widget.mode == InfoPageMode.edit && mounted) Navigator.pop(context);
      // onboarding 모드는 AuthGate가 step을 보고 자동 이동
    } catch (e) {
      _snack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _moneyField(TextEditingController ctrl) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          ThousandsFormatter(),
        ],
        decoration: const InputDecoration(
          suffixText: '₩',
          hintText: '0',
        ),
      ),
    );
  }

  Widget _checkRow({
    required String label,
    required bool checked,
    required VoidCallback onTap,
    required TextEditingController moneyCtrl,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(value: checked, onChanged: (_) => onTap()),
      title: Text(label),
      trailing: checked ? _moneyField(moneyCtrl) : const SizedBox(width: 160),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == InfoPageMode.onboarding ? '나의 정보 입력' : '나의 정보 수정';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('기본 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mainIncomeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
                    decoration: const InputDecoration(labelText: '주수익', suffixText: '₩'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subIncomeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
                    decoration: const InputDecoration(labelText: '부수익(선택)', suffixText: '₩'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _jobCtrl, decoration: const InputDecoration(labelText: '직업')),
                  const SizedBox(height: 12),
                  TextField(controller: _regionCtrl, decoration: const InputDecoration(labelText: '지역')),

                  const SizedBox(height: 24),
                  const Text('현재 관리 수단 (선택 + 금액)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...managementItems.map((k) {
                    final checked = _selectedManagement.contains(k);
                    return _checkRow(
                      label: k,
                      checked: checked,
                      moneyCtrl: _managementCtrls[k]!,
                      onTap: () {
                        setState(() {
                          if (checked) {
                            _selectedManagement.remove(k);
                            _managementCtrls[k]!.text = '';
                          } else {
                            _selectedManagement.add(k);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 24),
                  const Text('고정 지출 (선택 + 금액)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...fixedCostItems.map((k) {
                    final checked = _selectedFixed.contains(k);
                    return _checkRow(
                      label: k,
                      checked: checked,
                      moneyCtrl: _fixedCtrls[k]!,
                      onTap: () {
                        setState(() {
                          if (checked) {
                            _selectedFixed.remove(k);
                            _fixedCtrls[k]!.text = '';
                          } else {
                            _selectedFixed.add(k);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(_saving ? '저장 중...' : (widget.mode == InfoPageMode.onboarding ? '다음(목표설정)' : '저장')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
