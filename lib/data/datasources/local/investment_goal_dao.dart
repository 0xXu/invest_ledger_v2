import 'package:uuid/uuid.dart';
import 'package:decimal/decimal.dart';

import '../../models/investment_goal.dart';
import '../../database/database_helper.dart';

class InvestmentGoalDao {
  static const String _tableName = 'investment_goals';

  Future<String> createGoal(InvestmentGoal goal) async {
    final db = await DatabaseHelper.database;
    final id = const Uuid().v4();

    await db.insert(_tableName, {
      'id': id,
      'user_id': goal.userId,
      'type': goal.type.name,
      'period': goal.period.name,
      'year': goal.year,
      'month': goal.month,
      'target_amount': goal.targetAmount.toString(),
      'description': goal.description,
      'created_at': goal.createdAt.toIso8601String(),
      'updated_at': goal.updatedAt?.toIso8601String(),
    });

    return id;
  }

  Future<InvestmentGoal?> getGoalById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToGoal(maps.first);
  }

  Future<List<InvestmentGoal>> getGoalsByUserId(String userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map(_mapToGoal).toList();
  }

  Future<InvestmentGoal?> getCurrentGoal({
    required String userId,
    required GoalType type,
    required GoalPeriod period,
    required int year,
    int? month,
  }) async {
    final db = await DatabaseHelper.database;

    String whereClause = 'user_id = ? AND type = ? AND period = ? AND year = ?';
    List<dynamic> whereArgs = [userId, type.name, period.name, year];

    if (period == GoalPeriod.monthly && month != null) {
      whereClause += ' AND month = ?';
      whereArgs.add(month);
    } else if (period == GoalPeriod.yearly) {
      whereClause += ' AND month IS NULL';
    }

    final maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return _mapToGoal(maps.first);
  }

  Future<void> updateGoal(InvestmentGoal goal) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {
        'type': goal.type.name,
        'period': goal.period.name,
        'year': goal.year,
        'month': goal.month,
        'target_amount': goal.targetAmount.toString(),
        'description': goal.description,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  InvestmentGoal _mapToGoal(Map<String, dynamic> map) {
    return InvestmentGoal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: GoalType.values.firstWhere((e) => e.name == map['type']),
      period: GoalPeriod.values.firstWhere((e) => e.name == map['period']),
      year: map['year'] as int,
      month: map['month'] as int?,
      targetAmount: Decimal.parse(map['target_amount'] as String),
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
