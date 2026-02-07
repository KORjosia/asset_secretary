import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  ThousandsFormatter({this.max = 999999999999});
  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final value = int.tryParse(digits) ?? 0;
    final clamped = value > max ? max : value;

    final formatted = NumberFormat.decimalPattern('ko_KR').format(clamped);
    // 커서 끝으로
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  final _mainIncomeCtrl = TextEditingController();
  final _subIncomeCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  bool _saving = false;

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
  void dispose() {
    _mainIncomeCtrl.dispose();
    _subIncomeCtrl.dispose();
    _jobCtrl.dispose();
    _regionCtrl.dispose();
    for (final c in _managementCtrls.values) c.dispose();
    for (final c in _fixedCtrls.values) c.dispose();
    super.dispose();
  }

  int _parseMoney(String s) {
    final digits = s.replaceAll(',', '').trim();
    return int.tryParse(digits.isEmpty ? '0' : digits) ?? 0;
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mainIncome = _parseMoney(_mainIncomeCtrl.text);
    final subIncome = _parseMoney(_subIncomeCtrl.text);
    final job = _jobCtrl.text.trim();
    final region = _regionCtrl.text.trim();

    if (mainIncome <= 0 || job.isEmpty || region.isEmpty) {
      _snack('주수익/직업/지역은 필수야.');
      return;
    }

    // 선택 항목 + 금액
    final management = <String, int>{};
    for (final k in _selectedManagement) {
      final v = _parseMoney(_managementCtrls[k]!.text);
      management[k] = v;
    }

    final fixedCosts = <String, int>{};
    for (final k in _selectedFixed) {
      final v = _parseMoney(_fixedCtrls[k]!.text);
      fixedCosts[k] = v;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'myInfo': {
          'mainIncome': mainIncome,
          'subIncome': subIncome,
          'job': job,
          'region': region,
          'managementTools': management, // {항목: 금액}
          'fixedCosts': fixedCosts,      // {항목: 금액}
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'myInfoCompleted': true,
      }, SetOptions(merge: true));

      _snack('저장 완료!');
      // AuthGate가 myInfoCompleted 감지 → 다음부터 MainShell로 들어감
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      _snack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 정보 입력'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
      },
    ),
  ],
),
      
      body: AbsorbPointer(
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
            TextField(
              controller: _jobCtrl,
              decoration: const InputDecoration(labelText: '직업'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regionCtrl,
              decoration: const InputDecoration(labelText: '지역'),
            ),

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
                child: Text(_saving ? '저장 중...' : '저장하고 시작하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
