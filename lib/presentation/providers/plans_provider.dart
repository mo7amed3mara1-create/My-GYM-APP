import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/plan_model.dart';
import '../../data/repositories/plan_repository.dart';

final planRepoProvider = Provider<PlanRepository>((ref) => PlanRepository());

class PlansNotifier extends StateNotifier<AsyncValue<List<PlanModel>>> {
  final PlanRepository _planRepo;

  PlansNotifier(this._planRepo) : super(const AsyncValue.loading()) {
    loadPlans();
  }

  Future<void> loadPlans() async {
    state = const AsyncValue.loading();
    try {
      final list = await _planRepo.getPlans();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPlan(PlanModel plan) async {
    await _planRepo.createPlan(plan);
    await loadPlans();
  }

  Future<void> updatePlan(PlanModel plan) async {
    await _planRepo.updatePlan(plan);
    await loadPlans();
  }

  Future<bool> deletePlan(int planId) async {
    final deletedHard = await _planRepo.deletePlan(planId);
    await loadPlans();
    return deletedHard;
  }
}

final plansProvider = StateNotifierProvider<PlansNotifier, AsyncValue<List<PlanModel>>>((ref) {
  final repo = ref.watch(planRepoProvider);
  return PlansNotifier(repo);
});

final activePlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final repo = ref.watch(planRepoProvider);
  return await repo.getPlans(onlyActive: true);
});
