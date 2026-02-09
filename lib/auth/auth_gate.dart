//asset_secretary\lib\auth\auth_gate.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../onboarding/info_page.dart';
import '../onboarding/goal_page.dart';
import '../onboarding/mentor_page.dart';
import '../onboarding/consult_page.dart';
import '../services/firestore_service.dart';
import '../screens/auth_landing_page.dart';

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
        if (user == null) return const AuthLandingPage();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final exists = docSnap.data?.exists == true;
            final data = docSnap.data?.data();

            // ✅ users 문서가 없으면 "생성 완료까지 기다렸다가" 다시 보여주기
            if (!exists || data == null) {
              return FutureBuilder(
                future: FirestoreService.ensureUserDoc(user.uid),
                builder: (context, f) {
                  if (f.connectionState != ConnectionState.done) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  return const InfoPage(mode: InfoPageMode.onboarding);
                },
              );
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
