// lib/features/portfolio/portfolio_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../utils/money_input_formatter.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final txs = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('포트폴리오')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('계좌', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...accounts.map((a) => Card(
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text('목적: ${a.purpose.name} • 잔액: ${a.balanceWon}원'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'balance') {
                        await _editBalance(context, ref, a);
                      } else if (v == 'delete') {
                        await ref.read(accountsProvider.notifier).remove(a.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'balance', child: Text('잔액 수정')),
                      PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _addAccount(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('계좌 추가'),
          ),

          const SizedBox(height: 20),
          const Text('입금/거래(행동)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (txs.isEmpty) const Text('아직 거래가 없어요.'),
          ...txs.reversed.take(20).map((t) => Card(
                child: ListTile(
                  title: Text('${t.type.name} • ${t.amountWon}원'),
                  subtitle: Text('accountId: ${t.accountId} • inflowKind: ${t.inflowKind.name}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(transactionsProvider.notifier).remove(t.id),
                  ),
                ),
              )),

          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: accounts.isEmpty ? null : () => _addTx(context, ref, accounts),
            icon: const Icon(Icons.add),
            label: const Text('입금 추가(테스트)'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    AccountPurpose purpose = AccountPurpose.saving;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('계좌 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '계좌명')),
              const SizedBox(height: 8),
              DropdownButtonFormField<AccountPurpose>(
                value: purpose,
                decoration: const InputDecoration(labelText: '목적'),
                items: AccountPurpose.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => purpose = v ?? AccountPurpose.saving),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('추가')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    await ref.read(accountsProvider.notifier).add(
          name: nameCtrl.text.trim(),
          purpose: purpose,
        );
  }

  Future<void> _editBalance(BuildContext context, WidgetRef ref, Account a) async {
    final ctrl = TextEditingController(text: a.balanceWon.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('잔액 수정'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: '잔액(원)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );

    if (ok != true) return;

    final won = int.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? a.balanceWon;
    await ref.read(accountsProvider.notifier).update(a.copyWith(balanceWon: won));
  }

  Future<void> _addTx(BuildContext context, WidgetRef ref, List<Account> accounts) async {
    String accountId = accounts.first.id;
    TxType type = TxType.inflow;
    InflowKind inflowKind = InflowKind.salaryOrManual;

    final amountCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('입금/거래 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: accountId,
                decoration: const InputDecoration(labelText: '계좌'),
                items: accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => accountId = v ?? accounts.first.id),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TxType>(
                value: type,
                decoration: const InputDecoration(labelText: '유형'),
                items: const [
                  DropdownMenuItem(value: TxType.inflow, child: Text('입금(inflow)')),
                  DropdownMenuItem(value: TxType.outflow, child: Text('지출(outflow)')),
                ],
                onChanged: (v) => setState(() => type = v ?? TxType.inflow),
              ),
              const SizedBox(height: 8),
              if (type == TxType.inflow)
                DropdownButtonFormField<InflowKind>(
                  value: inflowKind,
                  decoration: const InputDecoration(labelText: '입금 종류(막대 포함/제외)'),
                  items: const [
                    DropdownMenuItem(
                      value: InflowKind.salaryOrManual,
                      child: Text('월급/수동입금(막대 포함)'),
                    ),
                    DropdownMenuItem(
                      value: InflowKind.interest,
                      child: Text('이자(막대 제외)'),
                    ),
                    DropdownMenuItem(
                      value: InflowKind.dividend,
                      child: Text('배당(막대 제외)'),
                    ),
                    DropdownMenuItem(
                      value: InflowKind.refund,
                      child: Text('환급(막대 제외)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => inflowKind = v ?? InflowKind.salaryOrManual),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter()],
                decoration: const InputDecoration(labelText: '금액(원)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('추가')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final amount = int.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    await ref.read(transactionsProvider.notifier).add(
          accountId: accountId,
          type: type,
          amountWon: amount,
          inflowKind: inflowKind,
        );
  }
}
