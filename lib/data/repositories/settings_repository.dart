import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/utils/password_helper.dart';
import '../database/app_database.dart';
import '../models/app_settings_model.dart';
import '../models/owner_model.dart';

class SettingsRepository {
  final AppDatabase _dbProvider;

  SettingsRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// Loads application settings.
  Future<AppSettingsModel> getSettings() async {
    final db = await _db;
    final rows = await db.query('settings');
    final Map<String, String> map = {};
    for (final row in rows) {
      map[row['key'] as String] = (row['value'] as String?) ?? '';
    }
    return AppSettingsModel.fromKeyValues(map);
  }

  /// Updates all settings in a single batch.
  Future<void> saveSettings(AppSettingsModel settings) async {
    final db = await _db;
    final map = settings.toKeyValues();
    await db.transaction((txn) async {
      for (final entry in map.entries) {
        await txn.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Updates last backup date.
  Future<void> recordBackupDone() async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': 'last_backup_date', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Checks if an owner/admin account exists.
  Future<bool> hasOwnerAccount() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT COUNT(*) AS count FROM owner');
    final count = (res.first['count'] as num?)?.toInt() ?? 0;
    return count > 0;
  }

  /// Checks whether user is logged in persistently.
  Future<bool> isLoggedIn() async {
    final db = await _db;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: ['is_logged_in'], limit: 1);
    if (rows.isEmpty) return false;
    return rows.first['value'] == '1';
  }

  /// Gets the currently logged in username from settings.
  Future<String?> getLoggedInUsername() async {
    final db = await _db;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: ['logged_in_username'], limit: 1);
    if (rows.isEmpty) return null;
    final val = rows.first['value'] as String?;
    return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
  }

  /// Sets login session.
  Future<void> saveSession({required bool isLoggedIn, required String username}) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'settings',
        {'key': 'is_logged_in', 'value': isLoggedIn ? '1' : '0'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'settings',
        {'key': 'logged_in_username', 'value': username.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Clears login session on logout.
  Future<void> clearSession() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'settings',
        {'key': 'is_logged_in', 'value': '0'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'settings',
        {'key': 'logged_in_username', 'value': ''},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Fetches default/first owner profile.
  Future<OwnerModel?> getOwner() async {
    final db = await _db;
    final rows = await db.query('owner', limit: 1);
    if (rows.isEmpty) return null;
    return OwnerModel.fromMap(rows.first);
  }

  /// Fetches all registered admins/captains.
  Future<List<OwnerModel>> getAllAdmins() async {
    final db = await _db;
    final rows = await db.query('owner', orderBy: 'created_at ASC');
    return rows.map((r) => OwnerModel.fromMap(r)).toList();
  }

  /// Fetches admin by username (case-insensitive).
  Future<OwnerModel?> getAdminByUsername(String username) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT * FROM owner WHERE LOWER(username) = LOWER(?) LIMIT 1',
      [username.trim()],
    );
    if (rows.isEmpty) return null;
    return OwnerModel.fromMap(rows.first);
  }

  /// Creates owner account on initial launch with salted hash.
  Future<void> createOwnerAccount(String username, String rawPassword, {String? displayName}) async {
    final db = await _db;
    final salt = PasswordHelper.generateSalt();
    final hash = PasswordHelper.hashPassword(rawPassword, salt);

    final owner = OwnerModel(
      username: username.trim(),
      passwordHash: hash,
      salt: salt,
      displayName: displayName ?? username.trim(),
      createdAt: DateTime.now(),
    );

    await db.insert('owner', owner.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Adds a new admin (returns false if username already taken).
  Future<bool> addAdmin({
    required String username,
    required String rawPassword,
    String? displayName,
  }) async {
    final existing = await getAdminByUsername(username);
    if (existing != null) return false;

    await createOwnerAccount(username, rawPassword, displayName: displayName);
    return true;
  }

  /// Deletes an admin (cannot delete if it's the only remaining admin).
  Future<bool> deleteAdmin(String username) async {
    final admins = await getAllAdmins();
    if (admins.length <= 1) return false;

    final db = await _db;
    final rowsDeleted = await db.delete(
      'owner',
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username.trim()],
    );
    return rowsDeleted > 0;
  }

  /// Verifies credentials for login or security check (case-insensitive username).
  Future<bool> verifyCredentials(String username, String rawPassword) async {
    final owner = await getAdminByUsername(username);
    if (owner == null) return false;

    return PasswordHelper.verifyPassword(
      password: rawPassword,
      salt: owner.salt,
      storedHash: owner.passwordHash,
    );
  }

  /// Changes owner password.
  Future<bool> changePassword(String currentPassword, String newPassword, {String? username}) async {
    final owner = username != null ? await getAdminByUsername(username) : await getOwner();
    if (owner == null) return false;

    final isValid = PasswordHelper.verifyPassword(
      password: currentPassword,
      salt: owner.salt,
      storedHash: owner.passwordHash,
    );
    if (!isValid) return false;

    final newSalt = PasswordHelper.generateSalt();
    final newHash = PasswordHelper.hashPassword(newPassword, newSalt);

    final db = await _db;
    await db.update(
      'owner',
      {
        'password_hash': newHash,
        'salt': newSalt,
      },
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [owner.username],
    );
    return true;
  }

  /// Resets owner account without wiping other tables.
  Future<void> resetOwnerAccount(String username, String newPassword) async {
    final db = await _db;
    await db.delete('owner');
    await createOwnerAccount(username, newPassword);
  }
}
