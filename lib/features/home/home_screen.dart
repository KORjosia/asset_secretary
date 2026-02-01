//C:\Users\user\asset_secretary\lib\features\home\home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/user_profile_provider.dart';
import '../../providers/portfolio_providers.dart';
import '../../providers/savings_goal_provider.dart';
import '../../providers/savings_goal_metrics_provider.dart';
import '../../utils/money_input_formatter.dart';
import '../../widgets/allocation_bar.dart';
import '../../widgets/radar_chart.dart';

final _currency = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
final _date = DateFormat('yyyy.MM.dd');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int newsIndex = 0;
  Timer? timer;

  final newsTitles = const [
    '공지: 포트폴리오 구조 업데이트 안내',
    '팁: 남은금액을 “비상금”으로 먼저 채워보세요',
    '안내: 이자/배당/환급은 막대(행동)에서 제외돼요',
    '기능: 계좌 목적을 지정하면 오각형이 자동 계산돼요',
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => newsIndex = (newsIndex + 1) % newsTitles.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _editMonthlyIncome(BuildContext context) async {
    final profile = ref.read(userProfileProvider);
    final ctrl = TextEditingController(
      text: profile.monthlyIncomeWon > 0 ? profile.monthlyIncomeWon.toString() : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('월 수익 입력'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: '월 수익(원)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );

    if (ok != true) return;

    final won = int.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? 0;
    await ref.read(userProfileProvider.notifier).setMonthlyIncome(won);
  }

  Future<void> _editGoalTarget(BuildContext context) async {
    final goal = ref.read(savingsGoalProvider);
    final ctrl = TextEditingController(
      text: goal.targetWon > 0 ? goal.targetWon.toString() : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('저축 목표금액 설정'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: '목표금액(원)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );

    if (ok != true) return;

    final target = int.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? 0;
    await ref.read(savingsGoalProvider.notifier).setTarget(target);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    final slices = ref.watch(allocationSlicesProvider);
    final extra = ref.watch(extraInflowProvider);
    final radar = ref.watch(radarScoreProvider);

    final goal = ref.watch(savingsGoalProvider);
    final goalMetrics = ref.watch(savingsGoalMetricsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('자산 비서')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✅ 프로필(간단 유지)
            Row(
              children: [
                InkWell(
                  onTap: () => _editMonthlyIncome(context),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('프로필', style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 12),

            // ✅ 저축 목표 (있던 영역 유지)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade600, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '저축 목표',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editGoalTarget(context),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                        label: Text(goal.targetWon > 0 ? '수정' : '설정',
                            style: const TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (goal.targetWon <= 0)
                    const Text(
                      '저축 목표금액 설정 후\n달성률 표시 and 달성 예상 날짜 계산',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w700),
                    )
                  else ...[
                    Text('목표: ${_currency.format(goalMetrics.targetWon)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('현재(목표계좌 잔액 합): ${_currency.format(goalMetrics.currentWon)}'),
                    Text('이번달(목표계좌 입금 합): ${_currency.format(goalMetrics.monthlyInflowWon)}'),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: goalMetrics.progress),
                    const SizedBox(height: 8),
                    Text(
                      '달성률: ${(goalMetrics.progress * 100).toStringAsFixed(1)}%  •  남은금액: ${_currency.format(goalMetrics.remainingWon)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      goalMetrics.remainingWon <= 0
                          ? '✅ 이미 목표를 달성했어요!'
                          : (goalMetrics.eta == null
                              ? '⚠️ 이번달 목표계좌 입금이 0원이라 예상 날짜를 계산할 수 없어요.'
                              : '📅 예상 달성일: ${_date.format(goalMetrics.eta!)}'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: goalMetrics.eta == null ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ 포트폴리오(막대 + 오각형) 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('포트폴리오', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    AllocationBar(slices: slices, extraInflowWon: extra),
                    const SizedBox(height: 14),
                    const Text(
                      '자산 구조 오각형',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '막대는 “이번 달 내가 한 행동(입금)”, 오각형은 “지금 상태(잔액)”를 봅니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    RadarChart(
                      values: radar.toList(),
                      labels: const ['안정성', '성장성', '유동성', '리스크', '부채관리'],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ (수정1) 공지(뉴스) → 오각형 하단으로 이동
            Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.campaign_outlined),
                title: Text(
                  newsTitles[newsIndex],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('5초마다 제목이 변경됩니다.'),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 12),

            // ✅ (수정2) 공지 바로 아래: 커뮤니티/전문가 반반 배치
            Row(
              children: [
                Expanded(
                  child: _HalfActionCard(
                    icon: Icons.forum_outlined,
                    title: '커뮤니티',
                    subtitle: '닉네임 기반 활동\n포트폴리오 카드 공유(예정)',
                    onTap: () {
                      // 탭 이동은 BottomBar로도 가능하지만, 홈에서도 눌리게 둠
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('커뮤니티 탭으로 이동하세요.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HalfActionCard(
                    icon: Icons.support_agent_outlined,
                    title: '전문가',
                    subtitle: '포트폴리오 공유 후\n상담 요청(예정)',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('상담 탭으로 이동하세요.')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HalfActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HalfActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
