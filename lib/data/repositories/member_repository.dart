import 'package:sqflite/sqflite.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../models/member_model.dart';
import '../models/subscription_model.dart';
import '../models/attendance_model.dart';
import '../models/payment_model.dart';

class MemberRepository {
  final AppDatabase _dbProvider;

  MemberRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// Generates a permanent unique 4-digit ID (1000–9999).
  /// Checks both `members` and `used_ids` table so deleted IDs are never reused.
  Future<int> generateUniqueMemberId() async {
    final db = await _db;
    return await IdGenerator.generateUniqueId(
      isIdUsed: (id) async {
        final result = await db.rawQuery(
          'SELECT 1 FROM used_ids WHERE id = ? UNION SELECT 1 FROM members WHERE id = ? LIMIT 1',
          [id, id],
        );
        return result.isNotEmpty;
      },
    );
  }

  /// Check if phone number is already registered to another member.
  Future<bool> isPhoneTaken(String phone, [int? excludeMemberId]) async {
    final db = await _db;
    final cleaned = phone.trim();
    String query = 'SELECT id FROM members WHERE phone = ?';
    List<dynamic> args = [cleaned];
    if (excludeMemberId != null) {
      query += ' AND id != ?';
      args.add(excludeMemberId);
    }
    final res = await db.rawQuery(query, args);
    return res.isNotEmpty;
  }

  /// Creates a member with their initial subscription and payment in a single atomic transaction.
  Future<void> createMemberWithSubscription({
    required MemberModel member,
    required SubscriptionModel subscription,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      // 1. Insert Member
      await txn.insert('members', member.toMap());

      // 2. Mark ID as permanently used
      await txn.insert('used_ids', {'id': member.id}, conflictAlgorithm: ConflictAlgorithm.ignore);

      // 3. Insert Subscription
      final subMap = subscription.toMap();
      if (subMap['total_sessions'] == null) {
        final planRows = await txn.query('plans', where: 'id = ?', whereArgs: [subscription.planId], limit: 1);
        if (planRows.isNotEmpty && planRows.first['total_sessions'] != null) {
          subMap['total_sessions'] = planRows.first['total_sessions'];
        }
      }
      final subId = await txn.insert('subscriptions', subMap);

      // 4. Record Payment if initial amount was paid
      if (subscription.amountPaid > 0) {
        await txn.insert('payments', {
          'member_id': member.id,
          'subscription_id': subId,
          'amount': subscription.amountPaid,
          'date': (subscription.paidAt ?? DateTime.now()).toIso8601String(),
        });
      }
    });
  }

  /// Updates member basic info (name, phone, notes).
  Future<void> updateMember(MemberModel member) async {
    final db = await _db;
    await db.update(
      'members',
      {
        'name': member.name,
        'phone': member.phone,
        'notes': member.notes,
      },
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  /// Deletes member, cascading to subscriptions, payments, and attendance.
  /// The ID stays permanently recorded in used_ids so it is never reused.
  Future<void> deleteMember(int memberId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('used_ids', {'id': memberId}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.delete('payments', where: 'member_id = ?', whereArgs: [memberId]);
      await txn.delete('attendance', where: 'member_id = ?', whereArgs: [memberId]);
      await txn.delete('subscriptions', where: 'member_id = ?', whereArgs: [memberId]);
      await txn.delete('members', where: 'id = ?', whereArgs: [memberId]);
    });
  }

  /// Retrieves members list with search, filter, and pagination.
  /// Efficient JOIN query loads latest subscription and attendance info.
  Future<List<MemberModel>> getMembers({
    String? searchQuery,
    String filter = 'all', // all, active, expiring, expired, unpaid
    int warningDays = 3,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db;
    final today = DateHelper.dateOnly(DateTime.now());

    String sql = '''
      SELECT 
        m.id, m.name, m.phone, m.notes, m.created_at,
        s.id AS sub_id, s.plan_id, s.start_date, s.end_date, s.price, s.amount_paid, s.is_paid, s.paid_at, s.created_at AS sub_created_at, s.total_sessions,
        p.name AS plan_name,
        (SELECT COUNT(*) FROM attendance WHERE member_id = m.id) AS total_visits,
        (SELECT COUNT(*) FROM attendance WHERE member_id = m.id AND date >= date(s.start_date) AND date <= date(s.end_date)) AS sub_visits,
        (SELECT MAX(date || ' ' || time) FROM attendance WHERE member_id = m.id) AS last_visit_str
      FROM members m
      LEFT JOIN subscriptions s ON s.id = (
        SELECT id FROM subscriptions WHERE member_id = m.id ORDER BY end_date DESC, id DESC LIMIT 1
      )
      LEFT JOIN plans p ON p.id = s.plan_id
      WHERE 1=1
    ''';

    final List<dynamic> params = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      sql += ' AND (m.name LIKE ? OR m.phone LIKE ? OR CAST(m.id AS TEXT) LIKE ?)';
      params.addAll([term, term, term]);
    }

    sql += ' ORDER BY m.created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    final rows = await db.rawQuery(sql, params);

    final List<MemberModel> list = [];
    for (final row in rows) {
      SubscriptionModel? sub;
      final subVisits = (row['sub_visits'] as num?)?.toInt() ?? 0;
      if (row['sub_id'] != null) {
        sub = SubscriptionModel(
          id: row['sub_id'] as int,
          memberId: row['id'] as int,
          planId: row['plan_id'] as int,
          startDate: DateTime.parse(row['start_date'] as String),
          endDate: DateTime.parse(row['end_date'] as String),
          price: (row['price'] as num).toDouble(),
          amountPaid: (row['amount_paid'] as num).toDouble(),
          isPaid: (row['is_paid'] as int) == 1,
          paidAt: row['paid_at'] != null ? DateTime.parse(row['paid_at'] as String) : null,
          createdAt: DateTime.parse(row['sub_created_at'] as String),
          totalSessions: (row['total_sessions'] as num?)?.toInt(),
          attendedSessions: subVisits,
          planName: row['plan_name'] as String?,
        );
      }

      DateTime? lastVisit;
      if (row['last_visit_str'] != null) {
        lastVisit = DateTime.tryParse(row['last_visit_str'] as String);
      }

      final member = MemberModel(
        id: row['id'] as int,
        name: row['name'] as String,
        phone: row['phone'] as String,
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        currentSubscription: sub,
        lastVisit: lastVisit,
        totalVisits: (row['total_visits'] as num?)?.toInt() ?? 0,
        subVisits: subVisits,
      );

      // Apply client-side filter cleanly based on computed subscription properties
      if (_matchesFilter(member, filter, warningDays, today)) {
        list.add(member);
      }
    }

    return list;
  }

  bool _matchesFilter(MemberModel member, String filter, int warningDays, DateTime today) {
    if (filter == 'all') return true;
    final sub = member.currentSubscription;
    if (sub == null) {
      return filter == 'expired';
    }

    switch (filter) {
      case 'active':
        return sub.isActive;
      case 'expiring':
        return sub.isExpiringSoon(warningDays);
      case 'expired':
        return sub.isExpired;
      case 'unpaid':
        return sub.hasRemainingDebt || !sub.isPaid;
      default:
        return true;
    }
  }

  /// Fetch single member by exact ID with latest subscription and stats.
  Future<MemberModel?> getMemberById(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT 
        m.id, m.name, m.phone, m.notes, m.created_at,
        s.id AS sub_id, s.plan_id, s.start_date, s.end_date, s.price, s.amount_paid, s.is_paid, s.paid_at, s.created_at AS sub_created_at, s.total_sessions,
        p.name AS plan_name,
        (SELECT COUNT(*) FROM attendance WHERE member_id = m.id) AS total_visits,
        (SELECT COUNT(*) FROM attendance WHERE member_id = m.id AND date >= date(s.start_date) AND date <= date(s.end_date)) AS sub_visits,
        (SELECT MAX(date || ' ' || time) FROM attendance WHERE member_id = m.id) AS last_visit_str
      FROM members m
      LEFT JOIN subscriptions s ON s.id = (
        SELECT id FROM subscriptions WHERE member_id = m.id ORDER BY end_date DESC, id DESC LIMIT 1
      )
      LEFT JOIN plans p ON p.id = s.plan_id
      WHERE m.id = ?
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    final row = rows.first;

    SubscriptionModel? sub;
    final subVisits = (row['sub_visits'] as num?)?.toInt() ?? 0;
    if (row['sub_id'] != null) {
      sub = SubscriptionModel(
        id: (row['sub_id'] as num).toInt(),
        memberId: (row['id'] as num).toInt(),
        planId: (row['plan_id'] as num).toInt(),
        startDate: DateTime.parse(row['start_date'] as String),
        endDate: DateTime.parse(row['end_date'] as String),
        price: (row['price'] as num).toDouble(),
        amountPaid: (row['amount_paid'] as num).toDouble(),
        isPaid: (row['is_paid'] as num).toInt() == 1,
        paidAt: row['paid_at'] != null ? DateTime.parse(row['paid_at'] as String) : null,
        createdAt: DateTime.parse(row['sub_created_at'] as String),
        totalSessions: (row['total_sessions'] as num?)?.toInt(),
        attendedSessions: subVisits,
        planName: row['plan_name'] as String?,
      );
    }

    DateTime? lastVisit;
    if (row['last_visit_str'] != null) {
      lastVisit = DateTime.tryParse(row['last_visit_str'] as String);
    }

    return MemberModel(
      id: (row['id'] as num).toInt(),
      name: row['name'] as String,
      phone: row['phone'] as String,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      currentSubscription: sub,
      lastVisit: lastVisit,
      totalVisits: (row['total_visits'] as num?)?.toInt() ?? 0,
      subVisits: subVisits,
    );
  }

  /// Toggles paid/unpaid status for the member's current subscription.
  /// If marking paid, fills remainder and adds payment record.
  /// If marking unpaid, sets amount_paid to 0 or adjusts.
  Future<void> toggleSubscriptionPaidStatus({
    required int subscriptionId,
    required int memberId,
    required bool markPaid,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final subRows = await txn.query('subscriptions', where: 'id = ?', whereArgs: [subscriptionId]);
      if (subRows.isEmpty) return;
      final sub = subRows.first;
      final price = (sub['price'] as num).toDouble();
      final currentPaid = (sub['amount_paid'] as num).toDouble();

      if (markPaid) {
        final remainder = price - currentPaid;
        await txn.update(
          'subscriptions',
          {
            'is_paid': 1,
            'amount_paid': price,
            'paid_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [subscriptionId],
        );

        if (remainder > 0) {
          await txn.insert('payments', {
            'member_id': memberId,
            'subscription_id': subscriptionId,
            'amount': remainder,
            'date': DateTime.now().toIso8601String(),
          });
        }
      } else {
        await txn.update(
          'subscriptions',
          {
            'is_paid': 0,
            'amount_paid': 0,
            'paid_at': null,
          },
          where: 'id = ?',
          whereArgs: [subscriptionId],
        );
        // Clear recent auto payments for this subscription
        await txn.delete('payments', where: 'subscription_id = ?', whereArgs: [subscriptionId]);
      }
    });
  }

  /// Attendance history for a member.
  Future<List<AttendanceModel>> getAttendanceHistory(int memberId) async {
    final db = await _db;
    final rows = await db.query(
      'attendance',
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'date DESC, time DESC',
    );
    return rows.map((r) => AttendanceModel.fromMap(r)).toList();
  }

  /// Subscription history for a member.
  Future<List<SubscriptionModel>> getSubscriptionHistory(int memberId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT s.*, p.name AS plan_name
      FROM subscriptions s
      LEFT JOIN plans p ON p.id = s.plan_id
      WHERE s.member_id = ?
      ORDER BY s.end_date DESC, s.id DESC
    ''', [memberId]);
    return rows.map((r) => SubscriptionModel.fromMap(r)).toList();
  }

  /// Payment history for a member.
  Future<List<PaymentModel>> getPaymentHistory(int memberId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT pay.*, p.name AS plan_name
      FROM payments pay
      LEFT JOIN subscriptions s ON s.id = pay.subscription_id
      LEFT JOIN plans p ON p.id = s.plan_id
      WHERE pay.member_id = ?
      ORDER BY pay.date DESC
    ''', [memberId]);
    return rows.map((r) => PaymentModel.fromMap(r)).toList();
  }
}
