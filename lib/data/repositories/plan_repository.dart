import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/plan_model.dart';

class PlanRepository {
  final AppDatabase _dbProvider;

  PlanRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  Future<List<PlanModel>> getPlans({bool onlyActive = false}) async {
    final db = await _db;
    final rows = await db.query(
      'plans',
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'duration_months ASC, price ASC',
    );
    return rows.map((r) => PlanModel.fromMap(r)).toList();
  }

  Future<int> createPlan(PlanModel plan) async {
    final db = await _db;
    return await db.insert('plans', plan.toMap());
  }

  Future<int> updatePlan(PlanModel plan) async {
    final db = await _db;
    return await db.update(
      'plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<bool> deletePlan(int planId) async {
    final db = await _db;
    // Check if any subscriptions use this plan
    final subs = await db.query('subscriptions', where: 'plan_id = ?', whereArgs: [planId], limit: 1);
    if (subs.isNotEmpty) {
      // Deactivate instead of deleting to preserve historical integrity
      await db.update('plans', {'is_active': 0}, where: 'id = ?', whereArgs: [planId]);
      return false; // Soft deleted / deactivated
    } else {
      await db.delete('plans', where: 'id = ?', whereArgs: [planId]);
      return true; // Hard deleted
    }
  }
}
