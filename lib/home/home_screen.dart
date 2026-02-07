//asset_secretary\lib\home\home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../onboarding/info_page.dart';
import '../onboarding/goal_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // ✅ AuthGate가 로그인 화면으로 이동시킴
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('홈화면 (더 개발 예정)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          ListTile(
            title: const Text('나의 정보 수정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InfoPage(mode: InfoPageMode.edit)),
              );
            },
          ),
          const Divider(height: 1),

          ListTile(
            title: const Text('목표 수정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalPage(mode: GoalPageMode.edit)),
              );
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
