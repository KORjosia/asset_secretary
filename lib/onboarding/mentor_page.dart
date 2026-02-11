//asset_secretary\lib\onboarding\mentor_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';

class MentorPage extends StatelessWidget {
  const MentorPage({super.key});

  static const bgTop = Color(0xFF0A1730);
  static const bgMid = Color(0xFF0B1833);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);

  // ✅ 기존 멘토 데이터 기반 + 피그마 카드용 확장 필드
  static final experts = [
    {
      'id': 'mentor_parksiksik',
      'name': '박종식',
      'avatar': 'PJS',
      'verified': true,
      'topRank': '상위 5%',
      'specialties': ['주식투자', '포트폴리오 관리'],
      'experience': '8년 이상',
      'rating': 4.8,
      'consultations': 410,
      'responseTime': '4시간 이내',
    },
    {
      'id': 'mentor_leeseonwoo',
      'name': '이선우',
      'avatar': 'LSW',
      'verified': true,
      'topRank': '상위 3%',
      'specialties': ['주식', '자산배분'],
      'experience': '10년 이상',
      'rating': 4.9,
      'consultations': 620,
      'responseTime': '3시간 이내',
    },
    {
      'id': 'mentor_limchanhyuk',
      'name': '임찬혁',
      'avatar': 'ICH',
      'verified': true,
      'topRank': '상위 10%',
      'specialties': ['보험', '노후설계'],
      'experience': '5년 이상',
      'rating': 4.7,
      'consultations': 280,
      'responseTime': '5시간 이내',
    },
  ];

  Future<void> _skip(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'onboardingStep': 'done',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _selectMentor(BuildContext context, Map<String, dynamic> mentor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'selectedMentor': {
        'id': mentor['id'],
        'name': mentor['name'],
        'selectedAt': FieldValue.serverTimestamp(),
      },
      'onboardingStep': 'consult',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전문가 상담', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 2),
            Text('인증된 재무 전문가와 연결하세요', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('검색은 추후 연결 예정이야.')),
              );
            },
            icon: const Icon(Icons.search_rounded, color: accent),
          ),
          TextButton(
            onPressed: () => _skip(context),
            child: const Text('건너뛰기', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            children: [
              // ✅ 6/6 progress
              _TopProgress(),

              const SizedBox(height: 12),

              // ✅ Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x141A2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x335B6B8A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: accent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('모든 전문가는 검증되었습니다',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('입증된 실적을 가진 공인 전문가',
                              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              ...experts.map((e) => _ExpertCard(
                    expert: e,
                    onTap: () => _selectMentor(context, e),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopProgress extends StatelessWidget {
  const _TopProgress();

  static const accent = Color(0xFF0AA3E3);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('멘토 선택', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w800)),
              Spacer(),
              Text('6/6', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 6,
              backgroundColor: Color(0x1FFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({required this.expert, required this.onTap});

  final Map<String, dynamic> expert;
  final VoidCallback onTap;

  static const accent = Color(0xFF0AA3E3);

  @override
  Widget build(BuildContext context) {
    final name = (expert['name'] ?? '').toString();
    final avatar = (expert['avatar'] ?? '').toString();
    final verified = (expert['verified'] ?? false) as bool;
    final topRank = (expert['topRank'] ?? '').toString();
    final rating = (expert['rating'] ?? 0).toString();
    final experience = (expert['experience'] ?? '').toString();
    final consultations = (expert['consultations'] ?? 0).toString();
    final responseTime = (expert['responseTime'] ?? '').toString();
    final specialties = (expert['specialties'] as List?)?.cast<String>() ?? const <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C1B34), Color(0xFF081427)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332B3F5E)),
        boxShadow: const [
          BoxShadow(blurRadius: 18, offset: Offset(0, 10), color: Color(0x22000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2F45),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatar,
                  style: const TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(width: 6),
                        if (verified) const Icon(Icons.check_circle_rounded, color: accent, size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Badge(text: topRank, filled: true),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, color: accent, size: 16),
                        const SizedBox(width: 2),
                        Text(rating, style: const TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Specialties
          const Text('전문분야', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialties
                .map((s) => _Badge(text: s, filled: false))
                .toList(),
          ),

          const SizedBox(height: 14),

          // Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x331A2A44),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x332B3F5E)),
            ),
            child: Row(
              children: [
                _Stat(label: '경력', value: experience),
                _V(),
                _Stat(label: '상담건수', value: consultations),
                _V(),
                _Stat(label: '응답시간', value: responseTime),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.message_rounded, size: 18),
              label: const Text('전문가에게 문의', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _V extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(width: 1, height: 28, child: DecoratedBox(decoration: BoxDecoration(color: Color(0x22FFFFFF)))),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.filled});
  final String text;
  final bool filled;

  static const accent = Color(0xFF0AA3E3);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? accent : const Color(0x1A0AA3E3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? Colors.transparent : const Color(0x330AA3E3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : accent,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
