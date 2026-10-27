import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_helper.dart';
import '../database/app_database.dart';
import '../models/attendance_model.dart';
import '../models/member_model.dart';
import '../models/subscription_model.dart';
import 'member_repository.dart';

enum CheckInStatus {
  success,
  warningExpiring,
  warningUnpaid,
  alreadyToday,
  expired,
  notFound,
}

class CheckInResult {
  final CheckInStatus status;
  final MemberModel? member;
  final String message;

  CheckInResult({
    required this.status,
    this.member,
    required this.message,
  });

  bool get isSuccessOrWarning =>
      status == CheckInStatus.success ||
      status == CheckInStatus.warningExpiring ||
      status == CheckInStatus.warningUnpaid;
}

class AttendanceRepository {
  final AppDatabase _dbProvider;
  final MemberRepository _memberRepo;

  AttendanceRepository([AppDatabase? dbProvider, MemberRepository? memberRepo])
      : _dbProvider = dbProvider ?? AppDatabase.instance,
        _memberRepo = memberRepo ?? MemberRepository(dbProvider);

  Future<Database> get _db async => await _dbProvider.database;

  /// Performs instant check-in for member ID.
  /// Enforces:
  /// - Member must exist
  /// - Expiry check
  /// - Duplicate daily check-in check
  /// - Warning window and debt warnings
  Future<CheckInResult> checkIn(int memberId, {int warningDays = 3}) async {
    final member = await _memberRepo.getMemberById(memberId);
    if (member == null) {
      return CheckInResult(
        status: CheckInStatus.notFound,
        message: AppStrings.checkInErrorNotFound,
      );
    }

    final sub = member.currentSubscription;
    if (sub == null || sub.isExpired) {
      final isSessionsOut = sub != null && sub.isSessionsDepleted;
      return CheckInResult(
        status: CheckInStatus.expired,
        member: member,
        message: isSessionsOut
            ? 'عفواً: نفدت جميع حصص هذا الاشتراك (${sub.totalSessions}/${sub.totalSessions} حصة). يرجى التجديد.'
            : AppStrings.checkInErrorExpired,
      );
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nowTimeStr = DateFormat('HH:mm:ss').format(DateTime.now());

    final db = await _db;

    // Check if already checked in today
    final existing = await db.query(
      'attendance',
      where: 'member_id = ? AND date = ?',
      whereArgs: [memberId, todayStr],
    );

    if (existing.isNotEmpty) {
      return CheckInResult(
        status: CheckInStatus.alreadyToday,
        member: member,
        message: AppStrings.checkInAlreadyToday,
      );
    }

    // Insert attendance record
    await db.insert('attendance', {
      'member_id': memberId,
      'date': todayStr,
      'time': nowTimeStr,
    });

    final newVisitsInSub = member.subVisits + 1;
    String successSuffix = '';
    if (sub.isSessionBased) {
      final remaining = (sub.totalSessions! - newVisitsInSub).clamp(0, 9999);
      successSuffix = ' (حصة $newVisitsInSub من ${sub.totalSessions} • متبقي $remaining حصص)';
    } else {
      successSuffix = ' (يوم الحضور رقم $newVisitsInSub في هذا الاشتراك)';
    }

    // Check for warnings
    if (sub.isExpiringSoon(warningDays)) {
      return CheckInResult(
        status: CheckInStatus.warningExpiring,
        member: member,
        message: '${AppStrings.checkInWarningExpiring} (${sub.daysLeft} ${AppStrings.daysLeft})$successSuffix',
      );
    }

    if (sub.hasRemainingDebt || !sub.isPaid) {
      return CheckInResult(
        status: CheckInStatus.warningUnpaid,
        member: member,
        message: '${AppStrings.checkInWarningUnpaid} (${sub.remainingAmount.toStringAsFixed(0)} ${AppStrings.currency})$successSuffix',
      );
    }

    return CheckInResult(
      status: CheckInStatus.success,
      member: member,
      message: '${AppStrings.checkInSuccess}$successSuffix',
    );
  }

  /// List of members who checked in today, latest first.
  Future<List<AttendanceModel>> getTodayCheckIns() async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final rows = await db.rawQuery('''
      SELECT 
        a.id, a.member_id, a.date, a.time,
        m.name AS member_name, m.phone,
        p.name AS plan_name,
        s.end_date, s.is_paid
      FROM attendance a
      JOIN members m ON m.id = a.member_id
      LEFT JOIN subscriptions s ON s.id = (
        SELECT id FROM subscriptions WHERE member_id = m.id ORDER BY end_date DESC, id DESC LIMIT 1
      )
      LEFT JOIN plans p ON p.id = s.plan_id
      WHERE a.date = ?
      ORDER BY a.time DESC, a.id DESC
    ''', [todayStr]);

    return rows.map((r) {
      int? daysLeft;
      if (r['end_date'] != null) {
        final end = DateTime.tryParse(r['end_date'] as String);
        if (end != null) {
          daysLeft = DateHelper.daysRemaining(end);
        }
      }

      return AttendanceModel(
        id: (r['id'] as num?)?.toInt() ?? 0,
        memberId: (r['member_id'] as num?)?.toInt() ?? 0,
        date: r['date'] as String? ?? '',
        time: r['time'] as String? ?? '',
        memberName: r['member_name'] as String?,
        phone: r['phone'] as String?,
        planName: r['plan_name'] as String?,
        daysLeft: daysLeft,
        isPaid: r['is_paid'] != null ? ((r['is_paid'] as num?)?.toInt() == 1) : null,
      );
    }).toList();
  }

  /// Removes an attendance record by ID (e.g. if checked in by mistake).
  Future<void> deleteAttendance(int attendanceId) async {
    final db = await _db;
    await db.delete('attendance', where: 'id = ?', whereArgs: [attendanceId]);
  }

  /// Finds active members who have not checked in for `thresholdDays` days.
  Future<List<MemberModel>> getAbsentMembers(int thresholdDays) async {
    final db = await _db;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final cutoffDate = DateHelper.dateOnly(now.subtract(Duration(days: thresholdDays)));
    final cutoffDateStr = DateFormat('yyyy-MM-dd').format(cutoffDate);

    final rows = await db.rawQuery('''
      SELECT 
        m.id, m.name, m.phone, m.notes, m.created_at,
        s.id AS sub_id, s.plan_id, s.start_date, s.end_date, s.price, s.amount_paid, s.is_paid, s.paid_at, s.created_at AS sub_created_at,
        p.name AS plan_name,
        (SELECT MAX(date || ' ' || time) FROM attendance WHERE member_id = m.id) AS last_visit_str
      FROM members m
      JOIN subscriptions s ON s.id = (
        SELECT id FROM subscriptions WHERE member_id = m.id ORDER BY end_date DESC, id DESC LIMIT 1
      )
      LEFT JOIN plans p ON p.id = s.plan_id
      WHERE date(s.end_date) >= ?
        AND (
          (SELECT MAX(date) FROM attendance WHERE member_id = m.id) < ?
          OR (SELECT COUNT(*) FROM attendance WHERE member_id = m.id) = 0
        )
      ORDER BY last_visit_str ASC
    ''', [todayStr, cutoffDateStr]);

    return rows.map((row) {
      final sub = SubscriptionModel(
        id: (row['sub_id'] as num?)?.toInt() ?? 0,
        memberId: (row['id'] as num?)?.toInt() ?? 0,
        planId: (row['plan_id'] as num?)?.toInt() ?? 0,
        startDate: DateTime.parse(row['start_date'] as String),
        endDate: DateTime.parse(row['end_date'] as String),
        price: (row['price'] as num).toDouble(),
        amountPaid: (row['amount_paid'] as num).toDouble(),
        isPaid: (row['is_paid'] as num?)?.toInt() == 1,
        paidAt: row['paid_at'] != null ? DateTime.parse(row['paid_at'] as String) : null,
        createdAt: DateTime.parse(row['sub_created_at'] as String),
        planName: row['plan_name'] as String?,
      );

      DateTime? lastVisit;
      if (row['last_visit_str'] != null) {
        lastVisit = DateTime.tryParse(row['last_visit_str'] as String);
      }

      return MemberModel(
        id: (row['id'] as num?)?.toInt() ?? 0,
        name: row['name'] as String,
        phone: row['phone'] as String,
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        currentSubscription: sub,
        lastVisit: lastVisit,
      );
    }).toList();
  }
}
