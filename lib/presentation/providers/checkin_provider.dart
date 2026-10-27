import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import 'members_provider.dart';
import 'settings_provider.dart';

final attendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  final memberRepo = ref.watch(memberRepoProvider);
  return AttendanceRepository(null, memberRepo);
});

class CheckInState {
  final AsyncValue<List<AttendanceModel>> todayListAsync;
  final CheckInResult? lastResult;
  final bool isSubmitting;

  CheckInState({
    this.todayListAsync = const AsyncValue.loading(),
    this.lastResult,
    this.isSubmitting = false,
  });

  CheckInState copyWith({
    AsyncValue<List<AttendanceModel>>? todayListAsync,
    CheckInResult? lastResult,
    bool? isSubmitting,
    bool clearLastResult = false,
  }) {
    return CheckInState(
      todayListAsync: todayListAsync ?? this.todayListAsync,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CheckInNotifier extends StateNotifier<CheckInState> {
  final AttendanceRepository _attendanceRepo;
  final Ref _ref;

  CheckInNotifier(this._attendanceRepo, this._ref) : super(CheckInState()) {
    loadTodayCheckIns();
  }

  Future<void> loadTodayCheckIns() async {
    try {
      final list = await _attendanceRepo.getTodayCheckIns();
      state = state.copyWith(todayListAsync: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(todayListAsync: AsyncValue.error(e, st));
    }
  }

  Future<CheckInResult> submitCheckIn(int memberId) async {
    state = state.copyWith(isSubmitting: true);
    final settings = _ref.read(settingsNotifierProvider).value;
    final warningDays = settings?.warningDays ?? 3;

    final result = await _attendanceRepo.checkIn(memberId, warningDays: warningDays);
    state = state.copyWith(
      isSubmitting: false,
      lastResult: result,
    );

    if (result.isSuccessOrWarning) {
      await loadTodayCheckIns();
      _ref.read(membersProvider.notifier).loadMembers();
    }

    return result;
  }

  Future<void> deleteAttendance(int attendanceId) async {
    await _attendanceRepo.deleteAttendance(attendanceId);
    await loadTodayCheckIns();
    _ref.read(membersProvider.notifier).loadMembers();
  }

  void clearResult() {
    state = state.copyWith(clearLastResult: true);
  }
}

final checkInProvider = StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  final repo = ref.watch(attendanceRepoProvider);
  return CheckInNotifier(repo, ref);
});
