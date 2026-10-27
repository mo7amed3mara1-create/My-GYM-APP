import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/date_helper.dart';
import '../database/app_database.dart';
import 'member_repository.dart';
import 'settings_repository.dart';

class BackupRepository {
  final AppDatabase _dbProvider;
  final SettingsRepository _settingsRepo;
  final MemberRepository _memberRepo;

  BackupRepository([
    AppDatabase? dbProvider,
    SettingsRepository? settingsRepo,
    MemberRepository? memberRepo,
  ])  : _dbProvider = dbProvider ?? AppDatabase.instance,
        _settingsRepo = settingsRepo ?? SettingsRepository(dbProvider),
        _memberRepo = memberRepo ?? MemberRepository(dbProvider);

  Future<Database> get _db async => await _dbProvider.database;

  /// Checks if backup reminder is due (older than 7 days from last backup or account creation).
  Future<bool> isBackupReminderDue() async {
    final settings = await _settingsRepo.getSettings();
    if (settings.lastBackupDate != null) {
      final days = DateTime.now().difference(settings.lastBackupDate!).inDays;
      return days >= 7;
    }

    // If no backup has been made yet, calculate days since owner account was created
    final owner = await _settingsRepo.getOwner();
    if (owner != null) {
      final days = DateTime.now().difference(owner.createdAt).inDays;
      return days >= 7;
    }

    return false;
  }

  /// Exports the entire database as a structured JSON file and opens the native share sheet.
  Future<String> exportDatabaseJson() async {
    final db = await _db;

    final members = await db.query('members');
    final usedIds = await db.query('used_ids');
    final plans = await db.query('plans');
    final subscriptions = await db.query('subscriptions');
    final payments = await db.query('payments');
    final attendance = await db.query('attendance');
    final settings = await db.query('settings');

    final backupData = {
      'app': 'MY_GYM',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'members': members,
      'used_ids': usedIds,
      'plans': plans,
      'subscriptions': subscriptions,
      'payments': payments,
      'attendance': attendance,
      'settings': settings,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/my_gym_backup_$dateStr.json');
    await file.writeAsString(jsonString, flush: true);

    // Record backup timestamp
    await _settingsRepo.recordBackupDone();

    // Trigger native share
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'MY GYM Backup - $dateStr',
    );

    return file.path;
  }

  /// Exports members list to CSV and opens share sheet.
  Future<String> exportMembersCsv() async {
    final members = await _memberRepo.getMembers(limit: 10000);

    final List<List<dynamic>> rows = [
      [
        'ID',
        'Name',
        'Phone',
        'Plan',
        'Start Date',
        'End Date',
        'Status',
        'Paid Status',
        'Total Visits',
        'Created At',
        'Notes',
      ],
    ];

    for (final m in members) {
      final sub = m.currentSubscription;
      String status = 'منتهي';
      if (sub != null && sub.isActive) {
        status = 'نشط (${sub.daysLeft} يوم متبقي)';
      }
      String paidStatus = sub != null ? (sub.isPaid ? 'مدفوع بالكامل' : 'غير مسدد') : '-';

      rows.add([
        m.id,
        m.name,
        m.phone,
        sub?.planName ?? '-',
        sub != null ? DateHelper.formatDate(sub.startDate) : '-',
        sub != null ? DateHelper.formatDate(sub.endDate) : '-',
        status,
        paidStatus,
        m.totalVisits,
        DateHelper.formatDate(m.createdAt),
        m.notes ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/my_gym_members_$dateStr.csv');
    // Prepend UTF-8 BOM so Excel opens Arabic correctly
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csvString)], flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'MY GYM Members - $dateStr',
    );

    return file.path;
  }

  /// Validates and restores complete database from JSON backup file.
  Future<bool> restoreDatabaseFromJson(String jsonContent) async {
    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic> || (decoded['app'] != 'MY_GYM' && decoded['app'] != 'AZM_GYM')) {
        return false;
      }

      final db = await _db;
      await db.transaction((txn) async {
        // Clear existing tables in safe order
        await txn.delete('payments');
        await txn.delete('attendance');
        await txn.delete('subscriptions');
        await txn.delete('plans');
        await txn.delete('members');
        await txn.delete('used_ids');
        await txn.delete('settings');

        // Restore members
        final members = (decoded['members'] as List<dynamic>?) ?? [];
        for (final m in members) {
          await txn.insert('members', Map<String, dynamic>.from(m as Map));
        }

        // Restore used_ids
        final usedIds = (decoded['used_ids'] as List<dynamic>?) ?? [];
        for (final u in usedIds) {
          await txn.insert('used_ids', Map<String, dynamic>.from(u as Map), conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        // Restore plans
        final plans = (decoded['plans'] as List<dynamic>?) ?? [];
        for (final p in plans) {
          await txn.insert('plans', Map<String, dynamic>.from(p as Map));
        }

        // Restore subscriptions
        final subscriptions = (decoded['subscriptions'] as List<dynamic>?) ?? [];
        for (final s in subscriptions) {
          await txn.insert('subscriptions', Map<String, dynamic>.from(s as Map));
        }

        // Restore payments
        final payments = (decoded['payments'] as List<dynamic>?) ?? [];
        for (final pay in payments) {
          await txn.insert('payments', Map<String, dynamic>.from(pay as Map));
        }

        // Restore attendance
        final attendance = (decoded['attendance'] as List<dynamic>?) ?? [];
        for (final a in attendance) {
          await txn.insert('attendance', Map<String, dynamic>.from(a as Map));
        }

        // Restore settings
        final settings = (decoded['settings'] as List<dynamic>?) ?? [];
        for (final set in settings) {
          await txn.insert('settings', Map<String, dynamic>.from(set as Map), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
