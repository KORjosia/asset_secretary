//asset_secretary\lib\onboarding\goal_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'money_formatter.dart';
import '../services/firestore_service.dart';

enum GoalPageMode { onboarding, edit }

class GoalPage extends StatefulWidget {
  const GoalPage({super.key, required this.mode});
  final GoalPageMode mode;

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  bool _loading = true;
  bool _saving = false;

  String _type = 'amount'; // amount | real_estate
  final _targetAmountCtrl = TextEditingController();

  // real_estate extra
  final _reRegionCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();

  int _risk = 1; // 1=안전, 5=위험
  int _months = 12; // 1~60

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
    final goal = (data?['goal'] as Map<String, dynamic>?) ?? {};

    _type = (goal['type'] as String?) ?? 'amount';
    _risk = (goal['riskLevel'] as int?) ?? 1;
    _months = (goal['durationMonths'] as int?) ?? 12;

    final ta = (goal['targetAmount'] as num?)?.toInt() ?? 0;
    _targetAmountCtrl.text = ta > 0 ? ta.toString() : '';
    // 포맷(콤마)
    if (_targetAmountCtrl.text.isNotEmpty) {
      _targetAmountCtrl.text = ThousandsFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: _targetAmountCtrl.text),
      ).text;
    }

    _reRegionCtrl.text = (goal['region'] as String?) ?? '';
    _buildingCtrl.text = (goal['buildingName'] as String?) ?? '';

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _targetAmountCtrl.dispose();
    _reRegionCtrl.dispose();
    _buildingCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetAmount = parseMoney(_targetAmountCtrl.text);
    if (targetAmount <= 0) {
      _snack('목표 금액을 입력해줘.');
      return;
    }

    if (_type == 'real_estate') {
      if (_reRegionCtrl.text.trim().isEmpty || _buildingCtrl.text.trim().isEmpty) {
        _snack('부동산 목표는 지역/건물명이 필요해.');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'goal': {
          'type': _type,
          'targetAmount': targetAmount,
          'riskLevel': _risk,
          'durationMonths': _months,
          if (_type == 'real_estate') 'region': _reRegionCtrl.text.trim(),
          if (_type == 'real_estate') 'buildingName': _buildingCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        if (widget.mode == GoalPageMode.onboarding) 'onboardingStep': 'mentor',
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            payload,
            SetOptions(merge: true),
          );

      if (widget.mode == GoalPageMode.onboarding) {
        await FirestoreService.setOnboardingStep(user.uid, 'mentor');
      }

      _snack('저장 완료!');
      if (widget.mode == GoalPageMode.edit && mounted) Navigator.pop(context);
    } catch (e) {
      _snack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == GoalPageMode.onboarding ? '목표 설정' : '목표 수정';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('목표 종류', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'amount', label: Text('금액 목표')),
                      ButtonSegment(value: 'real_estate', label: Text('부동산 목표')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetAmountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
                    decoration: const InputDecoration(labelText: '목표 금액', suffixText: '₩'),
                  ),

                  if (_type == 'real_estate') ...[
                    const SizedBox(height: 12),
                    TextField(controller: _reRegionCtrl, decoration: const InputDecoration(labelText: '부동산 지역')),
                    const SizedBox(height: 12),
                    TextField(controller: _buildingCtrl, decoration: const InputDecoration(labelText: '건물명')),
                  ],

                  const SizedBox(height: 24),
                  Text('투자 성향 (1=안전, 5=위험): $_risk',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _risk.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_risk',
                    onChanged: (v) => setState(() => _risk = v.round()),
                  ),

                  const SizedBox(height: 12),
                  Text('희망 기간(개월): $_months',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _months.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '$_months',
                    onChanged: (v) => setState(() => _months = v.round()),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(_saving ? '저장 중...' : (widget.mode == GoalPageMode.onboarding ? '다음(멘토찾기)' : '저장')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
