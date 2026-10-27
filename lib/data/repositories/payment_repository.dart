import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/date_helper.dart';
import '../database/app_database.dart';
import '../models/dashboard_stats_model.dart';

class RevenueMetrics {
  final double collectedThisMonth;
  final double expectedThisMonth;
  final double outstandingAmount;
  final int newMembersCount;
  final int renewalsCount;
  final int expiredCount;
  final Map<String, double> pastMonthsRevenue;
  final Map<String, int> planBreakdown;

  RevenueMetrics({
    required this.collectedThisMonth,
    required this.expectedThisMonth,
    required this.outstandingAmount,
    required this.newMembersCount,
    required this.renewalsCount,
    required this.expiredCount,
    required this.pastMonthsRevenue,
    required this.planBreakdown,
  });
}

class PaymentRepository {
  final AppDatabase _dbProvider;

  PaymentRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// Calculates real-time revenue metrics according to exact business rules:
  /// - Collected this month = sum of payments whose date falls in the month.
  /// - Expected this month = collected + unpaid remainder on active subscriptions + expected renewals of subscriptions ending this month (at current plan price).
  /// - Outstanding = total unpaid remainder across all members.
  Future<RevenueMetrics> getRevenueMetrics(DateTime targetMonth) async {
    final db = await _db;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final startOfTarget = DateHelper.startOfMonth(targetMonth);
    final endOfTarget = DateHelper.endOfMonth(targetMonth);

    final startStr = startOfTarget.toIso8601String();
    final endStr = endOfTarget.toIso8601String();

    // 1. Collected this month: sum of payments in target month
    final collectedRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total_collected
      FROM payments
      WHERE date >= ? AND date <= ?
    ''', [startStr, endStr]);
    final collected = (collectedRes.first['total_collected'] as num).toDouble();

    // 2. Unpaid remainder on currently active subscriptions
    final activeRemainderRes = await db.rawQuery('''
      SELECT COALESCE(SUM(price - amount_paid), 0) AS active_debt
      FROM subscriptions
      WHERE date(end_date) >= ?
        AND (price - amount_paid) > 0
    ''', [todayStr]);
    final activeDebt = (activeRemainderRes.first['active_debt'] as num).toDouble();

    // 3. Expected renewals of subscriptions ending in this target month (at plan price)
    final expectedRenewalsRes = await db.rawQuery('''
      SELECT COALESCE(SUM(s.price), 0) AS expected_renewal_sum
      FROM subscriptions s
      WHERE s.end_date >= ? AND s.end_date <= ?
    ''', [startStr, endStr]);
    final expectedRenewals = (expectedRenewalsRes.first['expected_renewal_sum'] as num).toDouble();

    final expectedThisMonth = collected + activeDebt + expectedRenewals;

    // 4. Total Outstanding: sum of all unpaid remainders across all subscriptions
    final outstandingRes = await db.rawQuery('''
      SELECT COALESCE(SUM(price - amount_paid), 0) AS total_outstanding
      FROM subscriptions
      WHERE (price - amount_paid) > 0
    ''');
    final outstanding = (outstandingRes.first['total_outstanding'] as num).toDouble();

    // 5. New members created in target month
    final newMembersRes = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM members
      WHERE created_at >= ? AND created_at <= ?
    ''', [startStr, endStr]);
    final newMembersCount = (newMembersRes.first['count'] as num).toInt();

    // 6. Renewals in target month (subscriptions where created_at is in month AND member had prior subscriptions)
    final renewalsRes = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM subscriptions s
      WHERE s.created_at >= ? AND s.created_at <= ?
        AND (SELECT COUNT(*) FROM subscriptions WHERE member_id = s.member_id AND created_at < s.created_at) > 0
    ''', [startStr, endStr]);
    final renewalsCount = (renewalsRes.first['count'] as num).toInt();

    // 7. Expired subscriptions in target month
    final expiredRes = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM subscriptions
      WHERE end_date >= ? AND end_date <= ?
        AND date(end_date) < ?
    ''', [startStr, endStr, todayStr]);
    final expiredCount = (expiredRes.first['count'] as num).toInt();

    // 8. Past 6 months revenue for chart
    final Map<String, double> pastMonthsRevenue = {};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(targetMonth.year, targetMonth.month - i, 1);
      final mStart = DateHelper.startOfMonth(m).toIso8601String();
      final mEnd = DateHelper.endOfMonth(m).toIso8601String();
      final label = DateFormat('MMM yyyy').format(m);

      final mRes = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) AS month_sum
        FROM payments
        WHERE date >= ? AND date <= ?
      ''', [mStart, mEnd]);

      pastMonthsRevenue[label] = (mRes.first['month_sum'] as num).toDouble();
    }

    // 9. Plan-wise breakdown of active members
    final planRes = await db.rawQuery('''
      SELECT p.name, COUNT(*) AS count
      FROM subscriptions s
      JOIN plans p ON p.id = s.plan_id
      WHERE date(s.end_date) >= ?
      GROUP BY p.id, p.name
      ORDER BY count DESC
    ''', [todayStr]);
    final Map<String, int> planBreakdown = {};
    for (final row in planRes) {
      planBreakdown[row['name'] as String] = (row['count'] as num).toInt();
    }

    return RevenueMetrics(
      collectedThisMonth: collected,
      expectedThisMonth: expectedThisMonth,
      outstandingAmount: outstanding,
      newMembersCount: newMembersCount,
      renewalsCount: renewalsCount,
      expiredCount: expiredCount,
      pastMonthsRevenue: pastMonthsRevenue,
      planBreakdown: planBreakdown,
    );
  }

  /// Calculates Dashboard live counters.
  Future<DashboardStatsModel> getDashboardStats(int warningDays) async {
    final db = await _db;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final warningDateStr = DateFormat('yyyy-MM-dd').format(now.add(Duration(days: warningDays)));

    // Active members
    final activeRes = await db.rawQuery('''
      SELECT COUNT(DISTINCT member_id) AS count
      FROM subscriptions
      WHERE date(end_date) >= ?
    ''', [todayStr]);
    final active = (activeRes.first['count'] as num).toInt();

    // Expiring soon: date(end_date) >= today AND date(end_date) <= today + warningDays
    final expiringRes = await db.rawQuery('''
      SELECT COUNT(DISTINCT member_id) AS count
      FROM subscriptions
      WHERE date(end_date) >= ?
        AND date(end_date) <= ?
    ''', [todayStr, warningDateStr]);
    final expiring = (expiringRes.first['count'] as num).toInt();

    // Expired members
    final expiredRes = await db.rawQuery('''
      SELECT COUNT(DISTINCT m.id) AS count
      FROM members m
      WHERE NOT EXISTS (
        SELECT 1 FROM subscriptions s 
        WHERE s.member_id = m.id AND date(s.end_date) >= ?
      )
    ''', [todayStr]);
    final expired = (expiredRes.first['count'] as num).toInt();

    // Today's check-ins
    final todayCheckInsRes = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM attendance
      WHERE date = ?
    ''', [todayStr]);
    final todayCheckIns = (todayCheckInsRes.first['count'] as num).toInt();

    final revenue = await getRevenueMetrics(now);

    return DashboardStatsModel(
      activeMembers: active,
      expiringSoon: expiring,
      expiredOverdue: expired,
      todayCheckIns: todayCheckIns,
      collectedThisMonth: revenue.collectedThisMonth,
      expectedThisMonth: revenue.expectedThisMonth,
      outstandingAmount: revenue.outstandingAmount,
      recentMonthsRevenue: revenue.pastMonthsRevenue,
      planDistribution: revenue.planBreakdown,
    );
  }
}
