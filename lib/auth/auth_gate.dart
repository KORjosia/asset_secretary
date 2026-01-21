import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_page.dart';
import '../app.dart'; // RootShell이 app.dart에 있으니 이 import 필요
import 'auth_providers.dart';

final authStateProvider = StreamProvider((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) => user == null ? const LoginPage() : const RootShell(),
    );
  }
}
