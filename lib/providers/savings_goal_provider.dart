//asset_secretary\lib\providers\savings_goal_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../models/savings_goal.dart';

final savingsGoalProvider =
    StateNotifierProvider<SavingsGoalController, SavingsGoal>((ref) {
  return SavingsGoalController()..load();
});

class SavingsGoalController extends StateNotifier<SavingsGoal> {
  SavingsGoalController() : super(const SavingsGoal(targetWon: 0));

  static const _key = 'savings_goal_v1';

  Future<void> load() async {
    final raw = LocalStore.get<Map>(_key);
    if (raw != null) state = SavingsGoal.fromJson(raw);
  }

  Future<void> save() async => LocalStore.set(_key, state.toJson());

  Future<void> setTarget(int won) async {
    state = SavingsGoal(targetWon: won.clamp(0, 1 << 60));
    await save();
  }

  Future<void> clear() async {
    state = const SavingsGoal(targetWon: 0);
    await save();
  }
}
