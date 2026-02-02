import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../models/user_profile.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileController, UserProfile>((ref) {
  return UserProfileController()..load();
});

class UserProfileController extends StateNotifier<UserProfile> {
  UserProfileController() : super(UserProfile.empty());

  static const _key = 'user_profile_v1';

  Future<void> load() async {
    final raw = LocalStore.get<Map>(_key);
    if (raw != null) state = UserProfile.fromJson(raw);
  }

  Future<void> save() async => LocalStore.set(_key, state.toJson());

  Future<void> updateProfile(UserProfile next) async {
    state = next;
    await save();
  }

  Future<void> setMonthlyIncome(int won) async {
    state = state.copyWith(monthlyIncomeWon: won.clamp(0, 1 << 60));
    await save();
  }

  Future<void> setSavingsGoal(int won) async {
    state = state.copyWith(savingsGoalWon: won.clamp(0, 1 << 60));
    await save();
  }
}
