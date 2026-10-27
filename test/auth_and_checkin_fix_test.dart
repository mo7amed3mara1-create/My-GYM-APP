import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:azm_gym/data/database/app_database.dart';
import 'package:azm_gym/data/models/member_model.dart';
import 'package:azm_gym/data/models/subscription_model.dart';
import 'package:azm_gym/data/repositories/member_repository.dart';
import 'package:azm_gym/data/repositories/settings_repository.dart';

class TestAppDatabase implements AppDatabase {
  final Database db;
  TestAppDatabase(this.db);

  @override
  Future<Database> get database async => db;

  @override
  Future<void> close() async => await db.close();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TestAppDatabase dbProvider;
  late SettingsRepository settingsRepo;
  late MemberRepository memberRepo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE used_ids (
        id INTEGER PRIMARY KEY
      )
    ''');
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        duration_months INTEGER NOT NULL,
        duration_days INTEGER,
        price REAL NOT NULL,
        total_sessions INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        plan_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        price REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        is_paid INTEGER NOT NULL DEFAULT 0,
        paid_at TEXT,
        total_sessions INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        subscription_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        UNIQUE (member_id, date)
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE owner (
        username TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        display_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    dbProvider = TestAppDatabase(db);
    settingsRepo = SettingsRepository(dbProvider);
    memberRepo = MemberRepository(dbProvider);
  });

  tearDown(() async {
    await db.close();
  });

  group('Session & Account Persistence Tests', () {
    test('hasOwnerAccount returns false initially, then true after creation', () async {
      expect(await settingsRepo.hasOwnerAccount(), isFalse);
      expect(await settingsRepo.isLoggedIn(), isFalse);

      await settingsRepo.createOwnerAccount('captain', 'pass123', displayName: 'Captain Ahmed');
      expect(await settingsRepo.hasOwnerAccount(), isTrue);

      final owner = await settingsRepo.getAdminByUsername('captain');
      expect(owner, isNotNull);
      expect(owner!.displayName, 'Captain Ahmed');
    });

    test('saveSession persists login state across app reloads', () async {
      await settingsRepo.createOwnerAccount('captain', 'pass123');
      await settingsRepo.saveSession(isLoggedIn: true, username: 'captain');

      expect(await settingsRepo.isLoggedIn(), isTrue);
      expect(await settingsRepo.getLoggedInUsername(), 'captain');

      // Logout clears session
      await settingsRepo.clearSession();
      expect(await settingsRepo.isLoggedIn(), isFalse);
      expect(await settingsRepo.getLoggedInUsername(), isNull);
    });
  });

  group('MemberRepository.getMemberById Exact Matching Tests (Bug Fix Verification)', () {
    test('getMemberById(1) returns member 1 even when member 10 with phone "01011111111" exists', () async {
      final now = DateTime.now();

      // Create Member 1
      await memberRepo.createMemberWithSubscription(
        member: MemberModel(
          id: 1,
          name: 'Ahmed First',
          phone: '01012345678',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        subscription: SubscriptionModel(
          memberId: 1,
          planId: 1,
          startDate: now.subtract(const Duration(days: 10)),
          endDate: now.add(const Duration(days: 20)),
          price: 350.0,
          amountPaid: 350.0,
          isPaid: true,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      );

      // Create Member 10 (created later, phone contains '1's)
      await memberRepo.createMemberWithSubscription(
        member: MemberModel(
          id: 10,
          name: 'Mahmoud Tenth',
          phone: '01111111111',
          createdAt: now,
        ),
        subscription: SubscriptionModel(
          memberId: 10,
          planId: 1,
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          price: 350.0,
          amountPaid: 350.0,
          isPaid: true,
          createdAt: now,
        ),
      );

      // Verify exact matching: ID 1 returns Member 1
      final m1 = await memberRepo.getMemberById(1);
      expect(m1, isNotNull);
      expect(m1!.id, 1);
      expect(m1.name, 'Ahmed First');

      // Verify exact matching: ID 10 returns Member 10
      final m10 = await memberRepo.getMemberById(10);
      expect(m10, isNotNull);
      expect(m10!.id, 10);
      expect(m10.name, 'Mahmoud Tenth');

      // Non-existent ID returns null
      final mNull = await memberRepo.getMemberById(999);
      expect(mNull, isNull);
    });
  });
}
