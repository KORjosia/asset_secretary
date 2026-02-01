// 위치: lib/app.dart
import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'features/home/home_screen.dart';
import 'features/community/community_screen.dart';
import 'features/stocks/stocks_screen.dart';
import 'features/consult/consult_screen.dart';
import 'features/safe_savings/safe_savings_screen.dart';

class AssetSecretaryApp extends StatelessWidget {
  const AssetSecretaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  // 0: 주식, 1: 커뮤니티, 2: 홈, 3: 상담, 4: 안전적금
  int index = 2;

  final pages = const [
    StocksScreen(),
    CommunityScreen(),
    HomeScreen(),
    ConsultScreen(),
    SafeSavingsScreen(),
  ];

  void _go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],

      // ✅ 가운데 홈 버튼
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _go(2),
        child: const Icon(Icons.home),
      ),

      // ✅ 스케치 느낌의 하단바 (중앙 홈은 FAB로)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.show_chart,
                label: '주식',
                selected: index == 0,
                onTap: () => _go(0),
              ),
              _NavItem(
                icon: Icons.forum_outlined,
                label: '커뮤니티',
                selected: index == 1,
                onTap: () => _go(1),
              ),

              // ✅ 가운데 홈 자리(노치 공간 확보용)
              const SizedBox(width: 30),

              _NavItem(
                icon: Icons.support_agent_outlined,
                label: '상담',
                selected: index == 3,
                onTap: () => _go(3),
              ),
              _NavItem(
                icon: Icons.savings_outlined,
                label: '안전적금',
                selected: index == 4,
                onTap: () => _go(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // ✅ 줄임
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22), // ✅ 살짝 줄임
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, // ✅ 줄임
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
                height: 1.0, // ✅ 라인높이 줄여 overflow 방지
              ),
            ),
          ],
        ),
      ),
    );
  }
}

