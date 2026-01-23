import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../models/goal.dart';

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

  Future<void> resetCurrentAmount() async {
    state = state.copyWith(currentAmountWon: 0);
    await save();
  }
}
