//asset_secretary\lib\providers\experts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/local_store.dart';
import '../models/expert.dart';
import '../models/expert_request.dart';

final expertsProvider = Provider<List<Expert>>((ref) {
  return const [
    Expert(id: 'e1', name: '김재무', field: '재무설계'),
    Expert(id: 'e2', name: '박투자', field: '투자'),
    Expert(id: 'e3', name: '이부채', field: '부채관리'),
  ];
});

final expertRequestsProvider =
    StateNotifierProvider<ExpertRequestsController, List<ExpertRequest>>((ref) {
  return ExpertRequestsController()..load();
});

class ExpertRequestsController extends StateNotifier<List<ExpertRequest>> {
  ExpertRequestsController() : super(const []);
  static const _key = 'expert_requests_v1';

  Future<void> load() async {
    final raw = LocalStore.get<List>(_key);
    if (raw == null) return;
    state = raw
        .map((e) => ExpertRequest.fromJson(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  Future<void> save() async =>
      LocalStore.set(_key, state.map((e) => e.toJson()).toList());

  Future<void> add(ExpertRequest r) async {
    state = [...state, r];
    await save();
  }
}
