import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('azm_gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // If desktop or test environment, initialize FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbFolder = Directory(p.join(appDocDir.path, 'AZMGym'));
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      path = p.join(dbFolder.path, filePath);
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onOpen: (db) async {
        // Run safe auto-migrations for all tables to ensure existing DB files are fully up-to-date
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS members (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              phone TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS used_ids (
              id INTEGER PRIMARY KEY
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS plans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              duration_months INTEGER NOT NULL,
              duration_days INTEGER,
              price REAL NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS subscriptions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              member_id INTEGER NOT NULL,
              plan_id INTEGER NOT NULL,
              start_date TEXT NOT NULL,
              end_date TEXT NOT NULL,
              price REAL NOT NULL,
              amount_paid REAL NOT NULL DEFAULT 0,
              is_paid INTEGER NOT NULL DEFAULT 0,
              paid_at TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE,
              FOREIGN KEY (plan_id) REFERENCES plans (id)
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              member_id INTEGER NOT NULL,
              subscription_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              date TEXT NOT NULL,
              FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE,
              FOREIGN KEY (subscription_id) REFERENCES subscriptions (id) ON DELETE CASCADE
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS attendance (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              member_id INTEGER NOT NULL,
              date TEXT NOT NULL,
              time TEXT NOT NULL,
              UNIQUE (member_id, date),
              FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS owner (
              username TEXT PRIMARY KEY,
              password_hash TEXT NOT NULL,
              salt TEXT NOT NULL,
              display_name TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE owner ADD COLUMN display_name TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE members ADD COLUMN notes TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE plans ADD COLUMN total_sessions INTEGER');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE subscriptions ADD COLUMN total_sessions INTEGER');
        } catch (_) {}
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance (date)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_member ON attendance (member_id)');
        } catch (_) {}
      },
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA cache_size = 2000');
    } catch (_) {}
  }

  static Future<void> _createDB(Database db, int version) async {
    // Members Table (Permanent unique numeric ID: 1, 2, 3...)
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Used IDs table to ensure IDs are permanent and collision-free
    await db.execute('''
      CREATE TABLE used_ids (
        id INTEGER PRIMARY KEY
      )
    ''');

    // Plans Table
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        duration_months INTEGER NOT NULL,
        duration_days INTEGER,
        price REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        total_sessions INTEGER
      )
    ''');

    // Subscriptions Table
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
        created_at TEXT NOT NULL,
        total_sessions INTEGER,
        FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE,
        FOREIGN KEY (plan_id) REFERENCES plans (id)
      )
    ''');

    // Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        subscription_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE,
        FOREIGN KEY (subscription_id) REFERENCES subscriptions (id) ON DELETE CASCADE
      )
    ''');

    // Attendance Table (Unique per member per day)
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        UNIQUE (member_id, date),
        FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE
      )
    ''');

    // Settings Table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Owner / Admins Table (Supports multiple admins)
    await db.execute('''
      CREATE TABLE owner (
        username TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        display_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Required Indexes for lightning performance
    await db.execute('CREATE INDEX idx_members_phone ON members (phone)');
    await db.execute('CREATE INDEX idx_subscriptions_member_id ON subscriptions (member_id)');
    await db.execute('CREATE INDEX idx_subscriptions_end_date ON subscriptions (end_date)');
    await db.execute('CREATE INDEX idx_attendance_member_date ON attendance (member_id, date)');
    await db.execute('CREATE INDEX idx_payments_date ON payments (date)');

    // Seed default plans
    await db.insert('plans', {
      'name': 'اشتراك شهر (Monthly)',
      'duration_months': 1,
      'duration_days': null,
      'price': 350.0,
      'is_active': 1,
    });
    await db.insert('plans', {
      'name': 'اشتراك 3 شهور (3 Months)',
      'duration_months': 3,
      'duration_days': null,
      'price': 900.0,
      'is_active': 1,
    });
    await db.insert('plans', {
      'name': 'اشتراك 6 شهور (6 Months)',
      'duration_months': 6,
      'duration_days': null,
      'price': 1600.0,
      'is_active': 1,
    });
    await db.insert('plans', {
      'name': 'اشتراك سنوي (Yearly)',
      'duration_months': 12,
      'duration_days': null,
      'price': 2800.0,
      'is_active': 1,
      'total_sessions': null,
    });
    await db.insert('plans', {
      'name': 'باقة 12 حصة (12 Sessions)',
      'duration_months': 1,
      'duration_days': null,
      'price': 400.0,
      'is_active': 1,
      'total_sessions': 12,
    });

    // Seed initial default settings
    await db.insert('settings', {'key': 'warning_days', 'value': '3'});
    await db.insert('settings', {'key': 'absence_threshold_days', 'value': '7'});
    await db.insert('settings', {'key': 'biometrics_enabled', 'value': '0'});
    await db.insert('settings', {'key': 'daily_reminder_enabled', 'value': '1'});
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
