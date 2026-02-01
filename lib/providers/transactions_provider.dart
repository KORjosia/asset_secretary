// 위치: lib/providers/transactions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../models/transaction.dart';

final transactionsProvider =
    StateNotifierProvider<TransactionsController, List<Tx>>((ref) {
  return TransactionsController()..load();
});

class TransactionsController extends StateNotifier<List<Tx>> {
  TransactionsController() : super(const []);
  static const _key = 'txs_v1';

  Future<void> load() async {
    final raw = LocalStore.get<List>(_key);
    if (raw == null) {
      // ✅ 첫 실행 임시 데이터(이번달 행동)
      final now = DateTime.now().millisecondsSinceEpoch;
      state = [
        Tx(
          id: 't1',
          accountId: 'a1',
          type: TxType.inflow,
          amountWon: 500000,
          createdAtMs: now,
          inflowKind: InflowKind.salaryOrManual,
        ),
        Tx(
          id: 't2',
          accountId: 'a2',
          type: TxType.inflow,
          amountWon: 300000,
          createdAtMs: now,
          inflowKind: InflowKind.salaryOrManual,
        ),
        Tx(
          id: 't3',
          accountId: 'a3',
          type: TxType.inflow,
          amountWon: 200000,
          createdAtMs: now,
          inflowKind: InflowKind.salaryOrManual,
        ),
        // ✅ 자동입금 예시(막대에서 제외)
        Tx(
          id: 't4',
          accountId: 'a1',
          type: TxType.inflow,
          amountWon: 12000,
          createdAtMs: now,
          inflowKind: InflowKind.dividend,
        ),
      ];
      await save();
      return;
    }

    state = raw.map((e) => Tx.fromJson(Map<dynamic, dynamic>.from(e))).toList();
  }

  Future<void> save() async =>
      LocalStore.set(_key, state.map((e) => e.toJson()).toList());

  Future<void> add({
    required String accountId,
    required TxType type,
    required int amountWon,
    InflowKind inflowKind = InflowKind.salaryOrManual,
  }) async {
    final tx = Tx(
      id: const Uuid().v4(),
      accountId: accountId,
      type: type,
      amountWon: amountWon.clamp(0, 1 << 60),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      inflowKind: inflowKind,
    );
    state = [...state, tx];
    await save();
  }

  Future<void> remove(String id) async {
    state = state.where((x) => x.id != id).toList();
    await save();
  }
}
