import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import 'settings_provider.dart';

final memberRepoProvider = Provider<MemberRepository>((ref) => MemberRepository());
final subscriptionRepoProvider = Provider<SubscriptionRepository>((ref) => SubscriptionRepository());

class MembersState {
  final String searchQuery;
  final String activeFilter; // all, active, expiring, expired, unpaid
  final AsyncValue<List<MemberModel>> membersAsync;

  MembersState({
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.membersAsync = const AsyncValue.loading(),
  });

  MembersState copyWith({
    String? searchQuery,
    String? activeFilter,
    AsyncValue<List<MemberModel>>? membersAsync,
  }) {
    return MembersState(
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      membersAsync: membersAsync ?? this.membersAsync,
    );
  }
}

class MembersNotifier extends StateNotifier<MembersState> {
  final MemberRepository _memberRepo;
  final Ref _ref;

  MembersNotifier(this._memberRepo, this._ref) : super(MembersState()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    state = state.copyWith(membersAsync: const AsyncValue.loading());
    try {
      final settings = _ref.read(settingsNotifierProvider).value;
      final warningDays = settings?.warningDays ?? 3;

      final members = await _memberRepo.getMembers(
        searchQuery: state.searchQuery,
        filter: state.activeFilter,
        warningDays: warningDays,
        limit: 500,
      );
      state = state.copyWith(membersAsync: AsyncValue.data(members));
    } catch (e, st) {
      state = state.copyWith(membersAsync: AsyncValue.error(e, st));
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadMembers();
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
    loadMembers();
  }

  Future<void> toggleSubscriptionPaid({
    required int memberId,
    required int subscriptionId,
    required bool markPaid,
  }) async {
    await _memberRepo.toggleSubscriptionPaidStatus(
      memberId: memberId,
      subscriptionId: subscriptionId,
      markPaid: markPaid,
    );
    await loadMembers();
  }

  Future<void> deleteMember(int memberId) async {
    await _memberRepo.deleteMember(memberId);
    await loadMembers();
  }
}

final membersProvider = StateNotifierProvider<MembersNotifier, MembersState>((ref) {
  final repo = ref.watch(memberRepoProvider);
  return MembersNotifier(repo, ref);
});

final memberDetailsProvider = FutureProvider.family<MemberModel?, int>((ref, memberId) async {
  final repo = ref.watch(memberRepoProvider);
  return await repo.getMemberById(memberId);
});
