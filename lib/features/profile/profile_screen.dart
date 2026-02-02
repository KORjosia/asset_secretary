//lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';

import 'my_page_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('마이페이지'),
              subtitle: const Text('내 정보 / 자금현황 / 설정'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPageScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
