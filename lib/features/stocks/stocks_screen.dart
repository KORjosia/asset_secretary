//asset_secretary\lib\features\stocks\stocks_screen.dart

import 'package:flutter/material.dart';

class StocksScreen extends StatelessWidget {
  const StocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주식')),
      body: const Center(child: Text('주식 화면(추가 예정)')),
    );
  }
}
