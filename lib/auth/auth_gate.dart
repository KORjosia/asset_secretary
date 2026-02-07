//asset_secretary\lib\auth\auth_gate.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_page.dart';
import '../home/home_screen.dart';
import '../onboarding/info_page.dart';
import '../onboarding/goal_page.dart';
import '../onboarding/mentor_page.dart';
import '../onboarding/consult_page.dart';
import '../services/firestore_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;
        if (user == null) return const LoginPage();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final exists = docSnap.data?.exists == true;
            final data = docSnap.data?.data();

            // 혹시 user 문서가 없으면(비정상 케이스) 최소 문서 생성 후 info로 보냄
            if (!exists || data == null) {
              FirestoreService.ensureUserDoc(user.uid);
              return const InfoPage(mode: InfoPageMode.onboarding);
            }

            final step = (data['onboardingStep'] as String?) ?? 'info';

            switch (step) {
              case 'info':
                return const InfoPage(mode: InfoPageMode.onboarding);
              case 'goal':
                return const GoalPage(mode: GoalPageMode.onboarding);
              case 'mentor':
                return const MentorPage();
              case 'consult':
                return const ConsultPage();
              case 'done':
              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
