//lib/features/profile/my_page_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';
import 'asset_status_page.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(userProfileProvider);

    String _line(String v) => v.trim().isEmpty ? '-' : v.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('내 기본 정보'),
              subtitle: Text(
                '직업: ${_line(p.job)}\n회사: ${_line(p.company)}\n지역: ${_line(p.region)}',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('자금현황 수정'),
              subtitle: const Text('직업/회사/지역/월수익/부수익/목표저축/월급날'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssetStatusPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
