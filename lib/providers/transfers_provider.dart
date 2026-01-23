import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../models/auto_transfer.dart';

final transfersProvider =
    StateNotifierProvider<TransfersController, List<AutoTransferPlan>>((ref) {
  return TransfersController()..load();
});

/// 목표 달성 월합계: "활성 + 저축(saving)"만
final monthlyTransferSumProvider = Provider<int>((ref) {
  final plans = ref.watch(transfersProvider);
  final activeSaving = plans.where((p) => p.isActive && p.type == TransferType.saving);
  return activeSaving.fold<int>(0, (sum, p) => sum + p.amountWon);
});

/// 월 지출 합계: "활성 + 지출(expense)"만
final monthlyExpenseSumProvider = Provider<int>((ref) {
  final plans = ref.watch(transfersProvider);
  final activeExpense = plans.where((p) => p.isActive && p.type == TransferType.expense);
  return activeExpense.fold<int>(0, (sum, p) => sum + p.amountWon);
});

class TransfersController extends StateNotifier<List<AutoTransferPlan>> {
  TransfersController() : super(const []);
  static const _key = 'transfers_v1';

  Future<void> load() async {
    final raw = LocalStore.get<List>(_key);
    if (raw == null) return;
    state = raw
        .map((e) => AutoTransferPlan.fromJson(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  Future<void> save() async =>
      LocalStore.set(_key, state.map((e) => e.toJson()).toList());

  Future<void> add(AutoTransferPlan p) async {
    state = [...state, p];
    await save();
  }

  Future<void> update(AutoTransferPlan p) async {
    state = [
      for (final x in state) if (x.id == p.id) p else x,
    ];
    await save();
  }

  Future<void> remove(String id) async {
    state = state.where((x) => x.id != id).toList();
    await save();
  }
}
