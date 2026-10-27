import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/member_model.dart';
import 'members_provider.dart';
import 'checkin_provider.dart';
import 'settings_provider.dart';

class AlertsState {
  final List<MemberModel> expiringSoon;
  final List<MemberModel> expiredOverdue;
  final List<MemberModel> absent;
  final bool isLoading;
  final String? errorMessage;

  AlertsState({
    this.expiringSoon = const [],
    this.expiredOverdue = const [],
    this.absent = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  AlertsState copyWith({
    List<MemberModel>? expiringSoon,
    List<MemberModel>? expiredOverdue,
    List<MemberModel>? absent,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AlertsState(
      expiringSoon: expiringSoon ?? this.expiringSoon,
      expiredOverdue: expiredOverdue ?? this.expiredOverdue,
      absent: absent ?? this.absent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final Ref _ref;

  AlertsNotifier(this._ref) : super(AlertsState()) {
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final memberRepo = _ref.read(memberRepoProvider);
      final attendanceRepo = _ref.read(attendanceRepoProvider);
      final settings = _ref.read(settingsNotifierProvider).value;

      final warningDays = settings?.warningDays ?? 3;
      final absenceDays = settings?.absenceThresholdDays ?? 7;

      // 1. Expiring soon
      final expiring = await memberRepo.getMembers(filter: 'expiring', warningDays: warningDays, limit: 200);

      // 2. Expired & Overdue / Unpaid
      final expired = await memberRepo.getMembers(filter: 'expired', limit: 200);
      final unpaid = await memberRepo.getMembers(filter: 'unpaid', limit: 200);

      // Merge expired & unpaid uniquely
      final Map<int, MemberModel> overdueMap = {};
      for (final m in expired) {
        overdueMap[m.id] = m;
      }
      for (final m in unpaid) {
        overdueMap[m.id] = m;
      }

      // 3. Absent active members
      final absent = await attendanceRepo.getAbsentMembers(absenceDays);

      state = state.copyWith(
        isLoading: false,
        expiringSoon: expiring,
        expiredOverdue: overdueMap.values.toList(),
        absent: absent,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  return AlertsNotifier(ref);
});
