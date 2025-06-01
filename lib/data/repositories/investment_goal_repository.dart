import 'package:decimal/decimal.dart';

import '../models/investment_goal.dart';
import '../datasources/local/investment_goal_dao.dart';

class InvestmentGoalRepository {
  final InvestmentGoalDao _goalDao;

  InvestmentGoalRepository(this._goalDao);

  Future<String> addGoal(InvestmentGoal goal) async {
    return await _goalDao.createGoal(goal);
  }

  Future<InvestmentGoal?> getGoalById(String id) async {
    return await _goalDao.getGoalById(id);
  }

  Future<List<InvestmentGoal>> getGoalsByUserId(String userId) async {
    return await _goalDao.getGoalsByUserId(userId);
  }

  Future<InvestmentGoal?> getCurrentGoal({
    required String userId,
    required GoalType type,
    required GoalPeriod period,
    required int year,
    int? month,
  }) async {
    return await _goalDao.getCurrentGoal(
      userId: userId,
      type: type,
      period: period,
      year: year,
      month: month,
    );
  }

  Future<void> updateGoal(InvestmentGoal goal) async {
    await _goalDao.updateGoal(goal);
  }

  Future<void> deleteGoal(String id) async {
    await _goalDao.deleteGoal(id);
  }

  Future<void> setOrUpdateGoal({
    required String userId,
    required GoalType type,
    required GoalPeriod period,
    required int year,
    int? month,
    required double targetAmount,
    String? description,
  }) async {
    final existingGoal = await getCurrentGoal(
      userId: userId,
      type: type,
      period: period,
      year: year,
      month: month,
    );

    if (existingGoal != null) {
      // Update existing goal
      final updatedGoal = existingGoal.copyWith(
        targetAmount: Decimal.parse(targetAmount.toString()),
        description: description,
        updatedAt: DateTime.now(),
      );
      await updateGoal(updatedGoal);
    } else {
      // Create new goal
      final newGoal = InvestmentGoal(
        userId: userId,
        type: type,
        period: period,
        year: year,
        month: month,
        targetAmount: Decimal.parse(targetAmount.toString()),
        description: description,
        createdAt: DateTime.now(),
      );
      await addGoal(newGoal);
    }
  }
}
