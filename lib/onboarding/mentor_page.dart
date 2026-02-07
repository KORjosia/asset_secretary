//asset_secretary\lib\onboarding\mentor_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class MentorPage extends StatelessWidget {
  const MentorPage({super.key});

  static final mentors = [
    {'id': 'mentor_parksiksik', 'name': '박종식', 'recommends': 10},
    {'id': 'mentor_leeseonwoo', 'name': '이선우', 'recommends': 11},
    {'id': 'mentor_limchanhyuk', 'name': '임찬혁', 'recommends': 12},
  ];


  List<Map<String, dynamic>> _sorted() {
    final copy = mentors.map((e) => Map<String, dynamic>.from(e)).toList();
    copy.sort((a, b) => (b['recommends'] as int).compareTo(a['recommends'] as int));
    return copy;
  }

  Future<void> _skip(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'onboardingStep': 'done',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirestoreService.setOnboardingStep(user.uid, 'done');
    // AuthGate가 홈으로 보내줌
  }

  Future<void> _selectMentor(BuildContext context, Map<String, dynamic> mentor,) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
     'selectedMentor': {
        'id': mentor['id'],      // ✅ 핵심
       'name': mentor['name'],
       'selectedAt': FieldValue.serverTimestamp(),
     },
     'onboardingStep': 'consult',
    }, SetOptions(merge: true));


    await FirestoreService.setOnboardingStep(user.uid, 'consult');
  }

  @override
  Widget build(BuildContext context) {
    final list = _sorted();

    return Scaffold(
      appBar: AppBar(
        title: const Text('멘토 찾기'),
        actions: [
          TextButton(
            onPressed: () => _skip(context),
            child: const Text('다음에 하기'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final m = list[i];
          final name = m['name'] as String;
          final rec = m['recommends'] as int;
          return ListTile(
            title: Text(name),
            subtitle: Text('추천 $rec개'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectMentor(context, m),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: list.length,
      ),
    );
  }
}
