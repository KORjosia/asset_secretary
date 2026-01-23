import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/auto_transfer.dart';
import '../../providers/transfers_provider.dart';
import '../../providers/goal_provider.dart';
import '../../utils/money_input_formatter.dart';

Color _transferTileColor(AutoTransferPlan p) {
  if (!p.isActive) return Colors.grey.shade200;
  if (p.type == TransferType.expense) return Colors.pink.shade50;
  return Colors.lightBlue.shade50;
}

final _currency = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');


int _monthsToGoal({required int remainingWon, required int monthly}) {
  if (remainingWon <= 0) return 0;
  if (monthly <= 0) return 1 << 30; // 사실상 무한
  return (remainingWon / monthly).ceil();
}


/// delay = afterMonths - beforeMonths
/// - null: afterMonthly가 0 → 예측 불가(사실상 달성 불가)
/// - 0: 지연 없음
/// - n: n개월 지연
int? _delayMonths({
  required int remainingWon,
  required int beforeMonthly,
  required int afterMonthly,
}) {
  final before = _monthsToGoal(remainingWon: remainingWon, monthly: beforeMonthly);
  final after = _monthsToGoal(remainingWon: remainingWon, monthly: afterMonthly);

  if (after >= (1 << 30)) return null;

  final d = after - before;
  return d <= 0 ? 0 : d;
}


class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(transfersProvider);
    final sortedPlans = [...plans]..sort((a, b) {
    int rank(AutoTransferPlan p) {
      if (!p.isActive) return 2; // 비활성 맨 아래
      return (p.type == TransferType.saving) ? 0 : 1; // 저축 → 지출
    }

      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);

      // 같은 그룹이면 날짜 순(선택)
      final d = a.dayOfMonth.compareTo(b.dayOfMonth);
      if (d != 0) return d;

      // 같으면 이름순(선택)
      return a.name.compareTo(b.name);
    });


    return Scaffold(
      appBar: AppBar(title: const Text('자동이체(시뮬레이션)')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: sortedPlans.length,
        itemBuilder: (ctx, i) {
          final p = sortedPlans[i];
          final typeLabel = (p.type == TransferType.saving) ? '저축' : '지출';

          return Card(
            color: _transferTileColor(p),
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(
                "매월 ${p.dayOfMonth}일 • ${_currency.format(p.amountWon)} • $typeLabel • ${p.isActive ? "활성" : "비활성"}",
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _openEditor(context, ref, existing: p);
                  } else if (v == 'delete') {
                    await _confirmDelete(context, ref, p);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('수정')),
                  PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
              onTap: () => _openEditor(context, ref, existing: p),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('추가'),
      ),
    );
  }

  /// ✅ 삭제 경고:
  /// - "저축(saving)+활성"인 경우에만 목표 달성 월합계 감소로 계산
  /// - 지출(expense)은 목표 달성 월합계에 영향 없으므로 delay=0 취급(문구도 분리 가능)
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AutoTransferPlan p,
  ) async {
    final goal = ref.read(goalProvider);
    final currentMonthly = ref.read(monthlyTransferSumProvider);

    final affectsGoal = p.isActive && p.type == TransferType.saving;
    final afterMonthly = affectsGoal
        ? (currentMonthly - p.amountWon).clamp(0, 1 << 60)
        : currentMonthly;

    final delay = _delayMonths(
      remainingWon: goal.remainingWon,
      beforeMonthly: currentMonthly,
      afterMonthly: afterMonthly,
    );

    final message = (goal.remainingWon <= 0)
        ? "이미 목표를 달성했어요 🎉\n그래도 이 자동이체를 삭제할까요?"
        : (!affectsGoal)
            ? "이 자동이체는 '지출'로 분류되어 목표 달성 기간에는 영향을 주지 않아요.\n그래도 삭제하시겠어요?"
            : (delay == null)
                ? "이 자동이체를 삭제하면 월 저축 자동이체 합계가 0원이 되어\n목표 달성 시점을 예측하기 어려워져요.\n\n삭제하시겠어요?"
                : (delay == 0)
                    ? "이 자동이체를 삭제해도 목표 달성 시점은 크게 변하지 않아요.\n\n삭제하시겠어요?"
                    : "⚠️ 이 자동이체를 삭제하면\n목표 달성이 약 ${delay}개월 늦어져요.\n\n그래도 삭제하시겠어요?";

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('자동이체 삭제 경고'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('유지'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(transfersProvider.notifier).remove(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자동이체가 삭제됐어요.')),
        );
      }
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    AutoTransferPlan? existing,
  }) 
  async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl =
        TextEditingController(text: existing != null ? existing.amountWon.toString() : '',);
    final dayCtrl =
        TextEditingController(text: existing != null ? existing.dayOfMonth.toString() : '',);

    bool active = existing?.isActive ?? true;
    TransferType type = existing?.type ?? TransferType.saving;

    final beforeAmount = existing?.amountWon;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          scrollable: true,
          title: Text(existing == null ? '자동이체 추가' : '자동이체 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: '자동이체 금액(원)'),
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter()],
              ),
              TextField(
                controller: dayCtrl,
                decoration: const InputDecoration(labelText: '매월 일자(1~28 추천)'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 8),
              DropdownButtonFormField<TransferType>(
                value: type,
                decoration: const InputDecoration(labelText: '유형'),
                items: const [
                  DropdownMenuItem(
                    value: TransferType.saving,
                    child: Text('저축/투자 (목표 달성)'),
                  ),
                  DropdownMenuItem(
                    value: TransferType.expense,
                    child: Text('고정지출 (월세/구독 등)'),
                  ),
                ],
                onChanged: (v) => setState(() => type = v ?? TransferType.saving),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (v) => setState(() => active = v),
                title: const Text('사용'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim().isEmpty ? '자동이체' : nameCtrl.text.trim();
    final amount = int.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ??
        (existing?.amountWon ?? 0);
    final day = int.tryParse(dayCtrl.text.trim()) ?? (existing?.dayOfMonth ?? 25);

    if (existing != null) {
      final reduced = beforeAmount != null && amount < beforeAmount;
      final deactivated = existing.isActive && !active;
      final typeChanged = existing.type != type;

      if (reduced || deactivated || typeChanged) {
        final goal = ref.read(goalProvider);
        final currentMonthly = ref.read(monthlyTransferSumProvider);

        // ✅ 목표달성 월합계에 영향 주는지(변경 전/후)를 saving+active 기준으로 판단
        final affectsGoalBefore =
            existing.isActive && existing.type == TransferType.saving;
        final affectsGoalAfter = active && type == TransferType.saving;

        int afterMonthly = currentMonthly;

        // (A) before에는 포함, after에는 제외 → 빼기
        if (affectsGoalBefore && !affectsGoalAfter) {
          afterMonthly = (afterMonthly - existing.amountWon).clamp(0, 1 << 60);
        }
        // (B) before에는 제외, after에는 포함 → 더하기
        else if (!affectsGoalBefore && affectsGoalAfter) {
          afterMonthly = (afterMonthly + amount).clamp(0, 1 << 60);
        }
        // (C) 둘 다 포함 → 금액 변경 반영
        else if (affectsGoalBefore && affectsGoalAfter) {
          if (beforeAmount != null && amount != beforeAmount) {
            afterMonthly =
                (afterMonthly - beforeAmount + amount).clamp(0, 1 << 60);
          }
        }

        final delay = _delayMonths(
          remainingWon: goal.remainingWon,
          beforeMonthly: currentMonthly,
          afterMonthly: afterMonthly,
        );

        final warnMsg = (goal.remainingWon <= 0)
            ? "이미 목표를 달성했어요 🎉\n그래도 변경할까요?"
            : (!affectsGoalBefore && !affectsGoalAfter)
                ? "이 변경은 '지출' 범위 내에서 이루어져 목표 달성 기간에는 영향을 주지 않아요.\n\n계속할까요?"
                : (delay == null)
                    ? "이 변경으로 월 저축 자동이체 합계가 0원이 되어\n목표 달성 시점을 예측하기 어려워져요.\n\n계속할까요?"
                    : (delay == 0)
                        ? "이 변경은 목표 달성 시점에 큰 영향을 주지 않아요.\n\n계속할까요?"
                        : "⚠️ 이 변경은 목표 달성을 약 ${delay}개월 늦출 수 있어요.\n\n계속할까요?";

        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('변경 경고'),
            content: Text(warnMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('아니요'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('계속'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    final plan = AutoTransferPlan(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      amountWon: amount,
      dayOfMonth: day.clamp(1, 28),
      isActive: active,
      type: type,
    );

    if (existing == null) {
      await ref.read(transfersProvider.notifier).add(plan);
    } else {
      await ref.read(transfersProvider.notifier).update(plan);
    }
  }
}