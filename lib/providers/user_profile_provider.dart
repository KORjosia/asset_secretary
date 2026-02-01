// 위치: lib/providers/user_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../models/user_profile.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileController, UserProfile>((ref) {
  return UserProfileController()..load();
});

class UserProfileController extends StateNotifier<UserProfile> {
  UserProfileController()
      : super(const UserProfile(
          monthlyIncomeWon: 0,
          paydayDay: 25,
        ));

  static const _key = 'user_profile_v1';

  Future<void> load() async {
    final raw = LocalStore.get<Map>(_key);
    if (raw != null) state = UserProfile.fromJson(raw);
  }

  Future<void> save() async => LocalStore.set(_key, state.toJson());

  Future<void> setMonthlyIncome(int won) async {
    state = state.copyWith(monthlyIncomeWon: won.clamp(0, 1 << 60));
    await save();
  }

  Future<void> setPaydayDay(int day) async {
    state = state.copyWith(paydayDay: day.clamp(1, 28));
    await save();
  }
}
