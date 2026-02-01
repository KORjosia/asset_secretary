// 위치: lib/providers/portfolio_providers.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import 'accounts_provider.dart';
import 'transactions_provider.dart';
import 'user_profile_provider.dart';

class AllocationSlice {
  final String label; // 계좌명 / 기타 / 남은금액
  final int amountWon;
  final double percentOfIncome; // 0~1
  final Color color;
  final bool isOthers;
  final bool isRemainder;

  const AllocationSlice({
    required this.label,
    required this.amountWon,
    required this.percentOfIncome,
    required this.color,
    this.isOthers = false,
    this.isRemainder = false,
  });
}

Color fixedColorFromSeed(int seed) {
  // seed 기반 HSV → 고정 색
  final h = (seed.abs() % 360).toDouble();
  final hsv = HSVColor.fromAHSV(1, h, 0.55, 0.90);
  return hsv.toColor();
}

/// ✅ 월급날 사이클(급여일~다음 급여일)
DateTime cycleStart(DateTime now, int paydayDay) {
  final day = paydayDay.clamp(1, 28);
  final thisMonth = DateTime(now.year, now.month, day);
  if (now.isBefore(thisMonth)) {
    final prev = DateTime(now.year, now.month - 1, day);
    return prev;
  }
  return thisMonth;
}

DateTime cycleEnd(DateTime now, int paydayDay) {
  final start = cycleStart(now, paydayDay);
  return DateTime(start.year, start.month + 1, start.day);
}

/// ✅ 막대에서 포함되는 inflow 조건
bool isCountedInflow(Tx tx) {
  if (tx.type != TxType.inflow) return false;
  return tx.inflowKind == InflowKind.salaryOrManual;
}

/// (홈) 계좌별 “이번달(사이클)” 입금 합
final accountInflowMapProvider = Provider<Map<String, int>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final txs = ref.watch(transactionsProvider);

  final now = DateTime.now();
  final start = cycleStart(now, profile.paydayDay);
  final end = cycleEnd(now, profile.paydayDay);
  final startMs = start.millisecondsSinceEpoch;
  final endMs = end.millisecondsSinceEpoch;

  final map = <String, int>{};

  for (final t in txs) {
    final inWindow = t.createdAtMs >= startMs && t.createdAtMs < endMs;
    if (!inWindow) continue;
    if (!isCountedInflow(t)) continue;

    map[t.accountId] = (map[t.accountId] ?? 0) + t.amountWon;
  }

  return map;
});

/// ✅ 홈 막대 슬라이스 (최대 6 + 기타 + 남은금액)
final allocationSlicesProvider = Provider<List<AllocationSlice>>((ref) {
  final income = ref.watch(userProfileProvider).monthlyIncomeWon;
  final accounts = ref.watch(accountsProvider);
  final inflowMap = ref.watch(accountInflowMapProvider);

  if (income <= 0) return const [];

  // 계좌별 inflow
  final items = <({Account a, int inflow})>[];
  for (final a in accounts) {
    final inflow = inflowMap[a.id] ?? 0;
    if (inflow <= 0) continue;
    items.add((a: a, inflow: inflow));
  }

  items.sort((x, y) => y.inflow.compareTo(x.inflow));

  // 최대 6개 + 기타
  final top = items.take(6).toList();
  final rest = items.skip(6).toList();
  final othersSum = rest.fold<int>(0, (s, x) => s + x.inflow);

  int totalIn = items.fold<int>(0, (s, x) => s + x.inflow);
  final remainder = max(0, income - totalIn);

  // percent는 income 기준, 전체는 100%로 클램프
  List<AllocationSlice> slices = [
    for (final x in top)
      AllocationSlice(
        label: x.a.name,
        amountWon: x.inflow,
        percentOfIncome: (x.inflow / income).clamp(0, 1),
        color: fixedColorFromSeed(x.a.colorSeed),
      ),
    if (othersSum > 0)
      AllocationSlice(
        label: '기타',
        amountWon: othersSum,
        percentOfIncome: (othersSum / income).clamp(0, 1),
        color: fixedColorFromSeed(999999),
        isOthers: true,
      ),
    if (remainder > 0)
      AllocationSlice(
        label: '남은금액',
        amountWon: remainder,
        percentOfIncome: (remainder / income).clamp(0, 1),
        color: Colors.grey.shade400,
        isRemainder: true,
      ),
  ];

  // ✅ 입금 합 > 월수익이면 100%로 클램프(남은금액 0)
  if (totalIn > income) {
    slices = [
      for (final s in slices.where((x) => !x.isRemainder))
        AllocationSlice(
          label: s.label,
          amountWon: s.amountWon,
          percentOfIncome: (s.amountWon / income).clamp(0, 1),
          color: s.color,
          isOthers: s.isOthers,
          isRemainder: false,
        ),
    ];
  }

  return slices;
});

/// ✅ “추가입금” 뱃지용 초과분
final extraInflowProvider = Provider<int>((ref) {
  final income = ref.watch(userProfileProvider).monthlyIncomeWon;
  final inflowMap = ref.watch(accountInflowMapProvider);
  final total = inflowMap.values.fold<int>(0, (s, v) => s + v);
  return max(0, total - income);
});

/// ----------------- 레이더(상태) -----------------
class RadarScore {
  final double stability;     // 안정성
  final double growth;        // 성장성
  final double liquidity;     // 유동성
  final double riskControl;   // 리스크(관리)
  final double debtControl;   // 부채관리

  const RadarScore({
    required this.stability,
    required this.growth,
    required this.liquidity,
    required this.riskControl,
    required this.debtControl,
  });

  List<double> toList() => [stability, growth, liquidity, riskControl, debtControl];
}

final radarScoreProvider = Provider<RadarScore>((ref) {
  final accounts = ref.watch(accountsProvider);

  int totalAssets = 0;
  int saving = 0, investing = 0, deposit = 0, emergency = 0, debt = 0, living = 0, other = 0;

  for (final a in accounts) {
    final b = max(0, a.balanceWon);
    totalAssets += b;
    switch (a.purpose) {
      case AccountPurpose.saving:
        saving += b;
        break;
      case AccountPurpose.investing:
        investing += b;
        break;
      case AccountPurpose.deposit:
        deposit += b;
        break;
      case AccountPurpose.emergencyFund:
        emergency += b;
        break;
      case AccountPurpose.debt:
        debt += b;
        break;
      case AccountPurpose.living:
        living += b;
        break;
      case AccountPurpose.other:
        other += b;
        break;
    }
  }

  if (totalAssets <= 0) {
    return const RadarScore(
      stability: 0.1,
      growth: 0.1,
      liquidity: 0.1,
      riskControl: 0.1,
      debtControl: 0.1,
    );
  }

  double r(int x) => (x / totalAssets).clamp(0, 1);

  final stableShare = r(saving + deposit + emergency);
  final growthShare = r(investing);

  // 유동성: 비상금 + 생활비(현금성) 비중
  final liquidityShare = r(emergency + living);

  // 리스크(관리): 투자비중이 “너무 높으면” 점수 하락, 비상금 있으면 보정
  final invest = growthShare;
  final emergencyBonus = (emergency > 0) ? 0.08 : 0.0;
  final riskControlBase =
      (1.0 - (invest * 1.15)).clamp(0.0, 1.0).toDouble();
  final riskControl = (riskControlBase + emergencyBonus).clamp(0.0, 1.0).toDouble();

  // 부채관리: debt 비중이 높을수록 점수 하락
  final debtShare = r(debt);
  final debtControl =
      (1.0 - (debtShare * 1.2)).clamp(0.0, 1.0).toDouble();


    return RadarScore(
    stability: stableShare,
    growth: growthShare,
    liquidity: liquidityShare,
    riskControl: riskControl,
    debtControl: debtControl,
  );
});
