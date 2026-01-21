import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local_store.dart';
import '../../models/goal.dart';
import '../../models/auto_transfer.dart';
import '../transfers/transfers_screen.dart';
import '../../utils/money_input_formatter.dart';


final _currency = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

final goalProvider = StateNotifierProvider<GoalController, Goal>((ref) {
  return GoalController()..load();
});

class GoalController extends StateNotifier<Goal> {
  GoalController()
      : super(const Goal(
          id: 'default',
          title: '첫 목표',
          targetAmountWon: 10000000,
          currentAmountWon: 0,
        ));

  Future<void> resetCurrentAmount() async {
    state = state.copyWith(currentAmountWon: 0);
    await save();
  }

  static const _key = 'goal_v1';

  Future<void> load() async {
    final raw = LocalStore.get<Map>(_key);
    if (raw != null) state = Goal.fromJson(raw);
  }

  Future<void> save() async => LocalStore.set(_key, state.toJson());

  Future<void> setGoal({required String title, required int targetWon}) async {
    state = state.copyWith(title: title, targetAmountWon: targetWon);
    await save();
  }

  Future<void> addProgress(int addWon) async {
    state = state.copyWith(currentAmountWon: state.currentAmountWon + addWon);
    await save();
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  static String? _lastAppliedKey;

  String _coachMessage(Goal g) {
    final p = g.progress;
    if (p >= 0.7) return "아주 좋아요! 이 페이스면 목표 달성 가능성이 높아요 👍";
    if (p >= 0.3) return "잘하고 있어요. 자동이체 유지가 핵심이에요 🙂";
    return "경고: 목표 달성이 느려요. 자동이체를 유지하거나 금액을 조정해봐요 ⚠️";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final yyyymmdd =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final key = 'applied_due_$yyyymmdd';

      if (_lastAppliedKey == key) return;
      _lastAppliedKey = key;

      applyDueTransfersIfNeeded(ref);
    });


    final goal = ref.watch(goalProvider);
    final monthly = ref.watch(monthlyTransferSumProvider);
    final remaining = goal.remainingWon;
    //final months = monthly <= 0 ? null : (remaining / monthly).ceil();
    final months = (monthly > 0 && remaining > 0) ? (remaining / monthly).ceil() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 비서'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('목표까지 남은 금액', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              _currency.format(goal.remainingWon),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: goal.progress),
            const SizedBox(height: 12),
            Text(_coachMessage(goal), style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            const SizedBox(height: 12),


            Card(
            child: ListTile(
               title: const Text('예상 달성 기간'),
               subtitle: Text(
                  remaining <= 0
                    ? '이미 목표를 달성했어요 🎉'
                    : monthly <= 0
                      ? '현재 활성 자동이체가 없어요. 자동이체를 설정하면 예상 기간을 계산해드려요.'
                      : '월 ${_currency.format(monthly)} 기준, 약 ${months}개월 예상',
               ),
                trailing: const Icon(Icons.timeline),
              ),
            ),
          

            Card(
              child: ListTile(
                title: Text(goal.title),
                subtitle: Text(
                  "목표: ${_currency.format(goal.targetAmountWon)} • 현재: ${_currency.format(goal.currentAmountWon)}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '목표 수정',
                  onPressed: () => _openEditGoal(context, ref, goal),
                ),
              ),
            ),
            const Spacer(),
            /*FilledButton.icon(
              onPressed: () async {
                await ref.read(goalProvider.notifier).addProgress(100000);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('₩100,000 진행이 추가됐어요!')),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('진행(₩100,000) 추가'),
            ),*/ //저금 직접 반영하는 것
          ],
        ),
      ),
    );
  }

  Future<void> applyDueTransfersIfNeeded(WidgetRef ref) async {
    final today = DateTime.now();
    final yyyymmdd = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'applied_due_$yyyymmdd';

    // 오늘 이미 반영한 자동이체 id들
    final applied = (LocalStore.get<List>(key) ?? []).cast<String>().toSet();

    final plans = ref.read(transfersProvider); // 전체 자동이체 목록
    final dueSavings = plans.where((p) =>
      p.isActive &&
      p.type == TransferType.saving &&
      p.dayOfMonth == today.day);

   int addTotal = 0;
   for (final p in dueSavings) {
      if (applied.contains(p.id)) continue;
      addTotal += p.amountWon;
      applied.add(p.id);
    }

    if (addTotal > 0) {
      await ref.read(goalProvider.notifier).addProgress(addTotal);
      await LocalStore.set(key, applied.toList());
    }
  }


  Future<void> _openEditGoal(BuildContext context, WidgetRef ref, Goal goal) async {
    
    final keepCurrent = await showDialog<bool>(
      context: context,
        builder: (ctx) => AlertDialog(
        title: const Text('목표 변경'),
        content: const Text(
          '목표를 변경할 때\n기존에 모은 금액을 유지할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('초기화'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('유지'),
          ),
        ],
      ),
    );
    

    if (keepCurrent == null) return;

    final titleCtrl = TextEditingController(text: goal.title);
    final targetCtrl = TextEditingController(text: goal.targetAmountWon.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('목표 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: '목표 이름'),
            ),
            TextField(
              controller: targetCtrl,
              decoration: const InputDecoration(labelText: '목표 금액(원)'),
              keyboardType: TextInputType.number,
               inputFormatters: [MoneyInputFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );

    if (result == true) {
      final title = titleCtrl.text.trim().isEmpty ? '목표' : titleCtrl.text.trim();
      final target = int.tryParse(targetCtrl.text.replaceAll(',', '').trim()) ?? goal.targetAmountWon;
      
      await ref.read(goalProvider.notifier).setGoal(
        title: title,
        targetWon: target,
      );

      if (!keepCurrent) {
        await ref.read(goalProvider.notifier).resetCurrentAmount();
      }

    }
  }
  
}

