//asset_secretary\lib\providers\savings_goal_metrics_provider.dart

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import 'accounts_provider.dart';
import 'portfolio_providers.dart';
import 'savings_goal_provider.dart';

class SavingsGoalMetrics {
  final int targetWon;
  final int currentWon; // 목표에 포함되는 계좌 잔액 합
  final int monthlyInflowWon; // 목표에 포함되는 계좌로 들어간 “수동/월급” 입금 합(이번 사이클)
  final double progress; // 0~1
  final int remainingWon;
  final DateTime? eta; // 예상 달성일(월 단위)

  const SavingsGoalMetrics({
    required this.targetWon,
    required this.currentWon,
    required this.monthlyInflowWon,
    required this.progress,
    required this.remainingWon,
    required this.eta,
  });
}

/// ✅ 목표에 포함할 목적(필요하면 너 취향대로 바꿔)
bool _isGoalPurpose(AccountPurpose p) {
  return p == AccountPurpose.saving ||
      p == AccountPurpose.deposit ||
      p == AccountPurpose.investing;
}

DateTime _addMonths(DateTime dt, int months) {
  final y = dt.year + ((dt.month - 1 + months) ~/ 12);
  final m = ((dt.month - 1 + months) % 12) + 1;
  final d = min(dt.day, DateTime(y, m + 1, 0).day);
  return DateTime(y, m, d);
}

final savingsGoalMetricsProvider = Provider<SavingsGoalMetrics>((ref) {
  final goal = ref.watch(savingsGoalProvider);
  final accounts = ref.watch(accountsProvider);
  final inflowMap = ref.watch(accountInflowMapProvider);

  final target = goal.targetWon;
  if (target <= 0) {
    return const SavingsGoalMetrics(
      targetWon: 0,
      currentWon: 0,
      monthlyInflowWon: 0,
      progress: 0,
      remainingWon: 0,
      eta: null,
    );
  }

  // 1) 현재잔액(상태) 기준: 목표 목적 계좌 잔액 합
  int current = 0;
  final goalAccountIds = <String>{};

  for (final a in accounts) {
    if (_isGoalPurpose(a.purpose)) {
      current += max(0, a.balanceWon);
      goalAccountIds.add(a.id);
    }
  }

  // 2) 이번 사이클 “행동” 기준: 목표 목적 계좌로 들어간 수동/월급 입금 합
  int monthlyInflow = 0;
  for (final id in goalAccountIds) {
    monthlyInflow += inflowMap[id] ?? 0;
  }

  final remaining = max(0, target - current);
  final progress = (current / target).clamp(0.0, 1.0).toDouble();

  DateTime? eta;
  if (remaining <= 0) {
    eta = DateTime.now();
  } else if (monthlyInflow > 0) {
    final months = (remaining / monthlyInflow).ceil();
    eta = _addMonths(DateTime.now(), months);
  } else {
    eta = null; // 예측 불가
  }

  return SavingsGoalMetrics(
    targetWon: target,
    currentWon: current,
    monthlyInflowWon: monthlyInflow,
    progress: progress,
    remainingWon: remaining,
    eta: eta,
  );
});
