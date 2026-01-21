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
              subtitle: Text('현재는 로컬 저장(Hive) 기반 MVP입니다.\n다음 단계에서 계좌/거래/알림/백엔드를 연결합니다.'),
            ),
          ),
        ],
      ),
    );
  }
}
