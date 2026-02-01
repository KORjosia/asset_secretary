// 위치: lib/providers/accounts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../models/account.dart';

final accountsProvider =
    StateNotifierProvider<AccountsController, List<Account>>((ref) {
  return AccountsController()..load();
});

class AccountsController extends StateNotifier<List<Account>> {
  AccountsController() : super(const []);
  static const _key = 'accounts_v1';

  Future<void> load() async {
    final raw = LocalStore.get<List>(_key);
    if (raw == null) {
      // ✅ 첫 실행 임시 데이터
      state = const [
        Account(
          id: 'a1',
          name: '미래에셋 ISA',
          purpose: AccountPurpose.investing,
          balanceWon: 2100000,
          colorSeed: 101,
        ),
        Account(
          id: 'a2',
          name: '기업 나라사랑 적금',
          purpose: AccountPurpose.saving,
          balanceWon: 1350000,
          colorSeed: 202,
        ),
        Account(
          id: 'a3',
          name: '비상금 통장',
          purpose: AccountPurpose.emergencyFund,
          balanceWon: 800000,
          colorSeed: 303,
        ),
        Account(
          id: 'a4',
          name: '생활비 통장',
          purpose: AccountPurpose.living,
          balanceWon: 250000,
          colorSeed: 404,
        ),
      ];
      await save();
      return;
    }

    state = raw
        .map((e) => Account.fromJson(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  Future<void> save() async =>
      LocalStore.set(_key, state.map((e) => e.toJson()).toList());

  Future<void> add({
    required String name,
    required AccountPurpose purpose,
  }) async {
    final id = const Uuid().v4();
    final seed = id.hashCode;
    final a = Account(
      id: id,
      name: name.trim().isEmpty ? '계좌' : name.trim(),
      purpose: purpose,
      balanceWon: 0,
      colorSeed: seed,
    );
    state = [...state, a];
    await save();
  }

  Future<void> update(Account a) async {
    state = [for (final x in state) if (x.id == a.id) a else x];
    await save();
  }

  Future<void> remove(String id) async {
    state = state.where((x) => x.id != id).toList();
    await save();
  }
}
