//asset_secretary\lib\app.dart
import 'package:flutter/material.dart';
import 'auth/auth_gate.dart';

class AssetSecretaryApp extends StatelessWidget {
  const AssetSecretaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}
