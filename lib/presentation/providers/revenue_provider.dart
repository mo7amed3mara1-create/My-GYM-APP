import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/repositories/payment_repository.dart';
import 'settings_provider.dart';

final paymentRepoProvider = Provider<PaymentRepository>((ref) => PaymentRepository());

final selectedReportMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final repo = ref.watch(paymentRepoProvider);
  final settings = ref.watch(settingsNotifierProvider).value;
  final warningDays = settings?.warningDays ?? 3;
  return await repo.getDashboardStats(warningDays);
});

final monthlyReportMetricsProvider = FutureProvider<RevenueMetrics>((ref) async {
  final repo = ref.watch(paymentRepoProvider);
  final selectedMonth = ref.watch(selectedReportMonthProvider);
  return await repo.getRevenueMetrics(selectedMonth);
});
