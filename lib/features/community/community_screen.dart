// 위치: lib/features/community/community_screen.dart
import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          Card(
            child: ListTile(
              title: Text('커뮤니티는 “포트폴리오 중심”으로 설계됩니다.'),
              subtitle: Text('닉네임 중심 활동\n글 작성 시 포트폴리오 카드 공유(예정)\nMVP에서는 계좌명이 그대로 노출될 수 있어요.'),
            ),
          ),
        ],
      ),
    );
  }
}
