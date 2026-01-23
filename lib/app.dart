import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/transfers/transfers_screen.dart';
import 'features/experts/experts_screen.dart';
import 'features/settings/settings_screen.dart';

import 'auth/auth_gate.dart';

class AssetSecretaryApp extends StatelessWidget {
  const AssetSecretaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '자비',
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
  int index = 0;

  final pages = const [
    HomeScreen(),
    TransfersScreen(),
    ExpertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: '자동이체'),
          NavigationDestination(icon: Icon(Icons.support_agent), label: '전문가'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
      ),
    );
  }
}
