//asset_secretary\lib\onboarding\consult_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  bool _loading = true;
  bool _sending = false;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _goal;
  String? _mentorName;
  String? _mentorId; // ✅ 추가: mentorId 보관

  final _qCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};

    _profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    _goal = (data['goal'] as Map<String, dynamic>?) ?? {};

    final selected = (data['selectedMentor'] as Map<String, dynamic>?) ?? {};
    _mentorName = (selected['name'] as String?) ?? '';
    _mentorId = (selected['id'] as String?) ?? ''; // ✅ 추가

    if (mounted) setState(() => _loading = false);
  }

  String _money(dynamic v) {
    final n = (v is int) ? v : (v is num ? v.toInt() : 0);
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '${buf.toString()}₩';
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mentor = (_mentorName ?? '').trim();
    if (mentor.isEmpty) {
      _snack('멘토가 선택되지 않았어. 멘토찾기 단계로 돌아가줘.');
      return;
    }

    final q = _qCtrl.text.trim();
    if (q.isEmpty) {
      _snack('질문을 입력해줘.');
      return;
    }
    if (q.length > 300) {
      _snack('질문은 300자 이하여야 해.');
      return;
    }

    final mentorId = (_mentorId ?? '').trim(); // ✅ 스코프 문제 해결

    setState(() => _sending = true);
    try {
      final reqRef =
          FirebaseFirestore.instance.collection('consult_requests').doc();

      // ✅ 상담 당시 스냅샷 보존
      await reqRef.set({
        'uid': user.uid,
        'mentorName': mentor,
        'mentorId': mentorId.isNotEmpty ? mentorId : mentor, // ✅ 임시 ID 대응
        'schemaVersion': 1, // ✅ 미래 대비
        'userProfileSnapshot': _profile ?? {},
        'goalSnapshot': _goal ?? {},
        'question': q,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'requested',
      });

      // ✅ 온보딩 종료 → 홈
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingStep': 'done',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirestoreService.setOnboardingStep(user.uid, 'done');

      _snack('상담 요청 완료!');
      // AuthGate가 홈으로 이동
    } catch (e) {
      _snack('요청 실패: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile ?? {};
    final goal = _goal ?? {};
    final mentor = (_mentorName ?? '').trim();

    final goalType = (goal['type'] as String?) ?? 'amount';
    final goalTitle = goalType == 'real_estate' ? '부동산 목표' : '금액 목표';

    return Scaffold(
      appBar: AppBar(title: const Text('상담 요청')),
      body: AbsorbPointer(
        absorbing: _sending,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('멘토: $mentor',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            const Text('정보 입력(스냅샷)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _kv('주수익', _money(profile['mainIncome'] ?? 0)),
            _kv('부수익', _money(profile['subIncome'] ?? 0)),
            _kv('직업', (profile['job'] ?? '').toString()),
            _kv('지역', (profile['region'] ?? '').toString()),

            const SizedBox(height: 16),
            const Text('목표 설정(스냅샷)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _kv('목표', goalTitle),
            if (goalType == 'real_estate') ...[
              _kv('부동산 지역', (goal['region'] ?? '').toString()),
              _kv('건물명', (goal['buildingName'] ?? '').toString()),
            ],
            _kv('목표금액', _money(goal['targetAmount'] ?? 0)),
            _kv('투자성향', '${goal['riskLevel'] ?? 1} (1=안전, 5=위험)'),
            _kv('희망기간', '${goal['durationMonths'] ?? 12}개월'),

            const SizedBox(height: 20),
            const Text('질문(최대 300자)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _qCtrl,
              maxLength: 300,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '멘토에게 남길 질문을 입력해줘.',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _send,
                child: Text(_sending ? '요청 중...' : '상담 요청 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
