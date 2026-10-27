import 'package:sqflite/sqflite.dart';
import '../../core/utils/date_helper.dart';
import '../database/app_database.dart';
import '../models/subscription_model.dart';
import '../models/plan_model.dart';

class SubscriptionRepository {
  final AppDatabase _dbProvider;

  SubscriptionRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// Determines default start date for renewal:
  /// If current subscription is still active, start date = day after current end date.
  /// If current subscription is expired, start date = today.
  DateTime calculateDefaultRenewalStartDate(SubscriptionModel? currentSub) {
    if (currentSub != null && currentSub.isActive) {
      return DateHelper.dateOnly(currentSub.endDate).add(const Duration(days: 1));
    }
    return DateHelper.dateOnly(DateTime.now());
  }

  /// Creates a renewal subscription and its associated payment.
  Future<int> renewSubscription({
    required int memberId,
    required PlanModel plan,
    required DateTime startDate,
    required double amountPaid,
    DateTime? overrideEndDate,
  }) async {
    final db = await _db;
    final endDate = overrideEndDate ??
        DateHelper.calculateEndDate(
          startDate,
          durationMonths: plan.durationMonths,
          durationDays: plan.durationDays,
        );

    final isPaid = amountPaid >= plan.price;
    final paidAt = amountPaid > 0 ? DateTime.now() : null;

    final sub = SubscriptionModel(
      memberId: memberId,
      planId: plan.id!,
      startDate: startDate,
      endDate: endDate,
      price: plan.price,
      amountPaid: amountPaid,
      isPaid: isPaid,
      paidAt: paidAt,
      createdAt: DateTime.now(),
      totalSessions: plan.totalSessions,
    );

    int subId = 0;
    await db.transaction((txn) async {
      subId = await txn.insert('subscriptions', sub.toMap());

      if (amountPaid > 0) {
        await txn.insert('payments', {
          'member_id': memberId,
          'subscription_id': subId,
          'amount': amountPaid,
          'date': (paidAt ?? DateTime.now()).toIso8601String(),
        });
      }
    });

    return subId;
  }
}
