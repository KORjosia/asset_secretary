// 위치: lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          Card(
            child: ListTile(
              title: Text('개발 메모'),
              subtitle: Text(
                '현재는 로컬 저장(Hive) 기반 MVP입니다.\n'
                '핵심: 입금(inflow)=행동, 잔액(balance)=상태\n'
                '추후 계좌 연동 데이터로 그대로 교체 가능한 구조입니다.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
