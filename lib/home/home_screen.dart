//asset_secretary\lib\home\home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../onboarding/info_page.dart';
import '../onboarding/goal_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const bgTop = Color(0xFF0A1730);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // ✅ AuthGate가 로그인/랜딩으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              _TopBar(
                onBellTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림은 추후 연결 예정이야.')),
                  );
                },
                onProfileTap: () async {
                  // 편의상 프로필 탭 = 로그아웃 메뉴
                  final r = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor: const Color(0xFF0B162C),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (_) => _ProfileSheet(
                      onLogout: () => Navigator.pop(context, 'logout'),
                      onEditInfo: () => Navigator.pop(context, 'editInfo'),
                      onEditGoal: () => Navigator.pop(context, 'editGoal'),
                    ),
                  );

                  if (r == 'logout') {
                    await _logout();
                  } else if (r == 'editInfo') {
                    // 홈에서 정보 수정
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InfoPage(mode: InfoPageMode.edit)),
                    );
                  } else if (r == 'editGoal') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoalPage(mode: GoalPageMode.edit)),
                    );
                  }
                },
              ),

              const SizedBox(height: 14),

              _ConsultCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('전문가 상담(상담요청/멘토 연결)은 추후 연결 예정이야.')),
                  );
                },
              ),

              const SizedBox(height: 14),

              _SectionTitle(
                title: '이달의 TOP 멘토',
                trailing: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('멘토 상세/전체보기는 추후 연결 예정이야.')),
                    );
                  },
                  icon: const Icon(Icons.person_search_rounded, color: Color(0x99FFFFFF), size: 18),
                ),
              ),
              const SizedBox(height: 8),
              _TopMentorCard(),

              const SizedBox(height: 14),

              _NewsCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('뉴스 연결은 추후 연결 예정이야.')),
                  );
                },
              ),

              const SizedBox(height: 14),

              _SectionTitle(
                title: '저축 목표 진행상황',
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('목표 상세/목표 관리 화면은 추후 연결 예정이야.')),
                    );
                  },
                  child: const Text(
                    '목표 관리',
                    style: TextStyle(color: Color(0xFF0AA3E3), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _GoalProgressEmptyCard(),
            ],
          ),
        ),
      ),

      // UI용 하단바(탭 연결은 추후)
      bottomNavigationBar: const _BottomNavMock(),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onProfileTap,
    required this.onBellTap,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onProfileTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x33FFFFFF)),
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/200'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // coin pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.monetization_on, size: 16, color: Color(0xFFFFD54A)),
              SizedBox(width: 6),
              Text(
                '100',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ],
          ),
        ),

        const Spacer(),

        IconButton(
          onPressed: onBellTap,
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.onLogout,
    required this.onEditInfo,
    required this.onEditGoal,
  });

  final VoidCallback onLogout;
  final VoidCallback onEditInfo;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 46, height: 5, decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 14),
          const Text('프로필', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Color(0xFF0AA3E3)),
            title: const Text('나의 정보 수정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            onTap: onEditInfo,
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Color(0xFF0AA3E3)),
            title: const Text('목표 수정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            onTap: onEditGoal,
          ),
          const Divider(color: Color(0x22FFFFFF)),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
            title: const Text('로그아웃', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _ConsultCard extends StatelessWidget {
  const _ConsultCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22C1F6), Color(0xFF0AA3E3)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(blurRadius: 20, offset: Offset(0, 10), color: Color(0x220AA3E3)),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.groups_2_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전문가 상담', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('최고의 전문가로부터\n효과적으로 관리하세요',
                      style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 11, height: 1.2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _TopMentorCard extends StatelessWidget {
  const _TopMentorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        children: const [
          _MentorRow(rank: 1, initials: 'LSW', name: '이선우', tag: '주식', badge: '중급자', delta: '+32%'),
          SizedBox(height: 10),
          _MentorRow(rank: 2, initials: 'PJS', name: '박종식', tag: '주식', badge: '중급자', delta: '+28%'),
          SizedBox(height: 10),
          _MentorRow(rank: 3, initials: 'ICH', name: '임찬혁', tag: '보험', badge: '초보', delta: '+25%'),
        ],
      ),
    );
  }
}

class _MentorRow extends StatelessWidget {
  const _MentorRow({
    required this.rank,
    required this.initials,
    required this.name,
    required this.tag,
    required this.badge,
    required this.delta,
  });

  final int rank;
  final String initials;
  final String name;
  final String tag;
  final String badge;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x121A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0AA3E3),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 10),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2F45),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(text: tag),
                    const SizedBox(width: 6),
                    _Chip(text: badge, filled: true),
                  ],
                ),
              ],
            ),
          ),

          Text(delta, style: const TextStyle(color: Color(0xFF3EDC85), fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0x99FFFFFF)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.filled = false});
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF0AA3E3) : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? const Color(0x00000000) : const Color(0x22FFFFFF)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: const  [
            const Icon(Icons.show_chart_rounded, color: HomeScreen.accent, size: 22),
            
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('금융 경제 뉴스', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('단타, 재테크 관련 정보 제공', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0x99FFFFFF)),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressEmptyCard extends StatelessWidget {
  const _GoalProgressEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: const Column(
        children: [
          SizedBox(height: 10),
          Icon(Icons.radio_button_checked, color: Color(0x33FFFFFF), size: 38),
          SizedBox(height: 10),
          Text('아직 저축 목표가 없습니다',
              style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w900, fontSize: 13)),
          SizedBox(height: 6),
          Text('원하는 저축 목표를 설정해주세요',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
          SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _BottomNavMock extends StatefulWidget {
  const _BottomNavMock();

  @override
  State<_BottomNavMock> createState() => _BottomNavMockState();
}

class _BottomNavMockState extends State<_BottomNavMock> {
  int index = 2; // 홈 강조(가운데)

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF071225),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.calendar_month_outlined, label: '달력', i: 0),
              _navItem(icon: Icons.analytics_outlined, label: '분석', i: 1),
              _navCenter(icon: Icons.home_rounded, label: '홈', i: 2),
              _navItem(icon: Icons.chat_bubble_outline, label: '커뮤니티', i: 3),
              _navItem(icon: Icons.person_outline, label: '마이', i: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int i}) {
    final selected = index == i;
    return GestureDetector(
      onTap: () => setState(() => index = i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? const Color(0xFF0AA3E3) : const Color(0x99FFFFFF), size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? const Color(0xFF0AA3E3) : const Color(0x99FFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _navCenter({required IconData icon, required String label, required int i}) {
    final selected = index == i;
    return GestureDetector(
      onTap: () => setState(() => index = i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0AA3E3),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(blurRadius: 18, offset: Offset(0, 10), color: Color(0x220AA3E3)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? const Color(0xFF0AA3E3) : const Color(0x99FFFFFF), fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
