import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/investment_goal.dart';
import '../../data/repositories/investment_goal_repository.dart';
import '../../data/datasources/local/investment_goal_dao.dart';
import '../../core/auth/auth_service.dart';
import 'transaction_provider.dart';
import 'loading_provider.dart';

part 'investment_goal_provider.g.dart';

// Repository providers
@riverpod
InvestmentGoalDao investmentGoalDao(InvestmentGoalDaoRef ref) {
  return InvestmentGoalDao();
}

@riverpod
InvestmentGoalRepository investmentGoalRepository(InvestmentGoalRepositoryRef ref) {
  return InvestmentGoalRepository(ref.watch(investmentGoalDaoProvider));
}

// Goal list provider
@riverpod
class InvestmentGoalNotifier extends _$InvestmentGoalNotifier {
  @override
  Future<List<InvestmentGoal>> build() async {
    final authState = ref.watch(authServiceProvider);
    if (authState.user == null) return [];

    final repository = ref.read(investmentGoalRepositoryProvider);
    return await repository.getGoalsByUserId(authState.user!.id);
  }

  Future<void> setGoal({
    required GoalType type,
    required GoalPeriod period,
    required int year,
    int? month,
    required double targetAmount,
    String? description,
    bool autoCalculateCounterpart = true,
  }) async {
    final authState = ref.read(authServiceProvider);
    if (authState.user == null) return;

    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(investmentGoalRepositoryProvider);

      // 保存当前目标
      await repository.setOrUpdateGoal(
        userId: authState.user!.id,
        type: type,
        period: period,
        year: year,
        month: month,
        targetAmount: targetAmount,
        description: description,
      );

      // 自动计算并设置对应的目标
      if (autoCalculateCounterpart) {
        if (period == GoalPeriod.monthly) {
          // 设置月度目标时，自动计算年度目标
          final yearlyTarget = targetAmount * 12;

          // 检查是否已有年度目标
          final existingYearlyGoal = await repository.getCurrentGoal(
            userId: authState.user!.id,
            type: type,
            period: GoalPeriod.yearly,
            year: year,
          );

          if (existingYearlyGoal == null) {
            await repository.setOrUpdateGoal(
              userId: authState.user!.id,
              type: type,
              period: GoalPeriod.yearly,
              year: year,
              month: null,
              targetAmount: yearlyTarget,
              description: description != null ? '基于月度目标自动计算: $description' : '基于月度目标自动计算',
            );
          }
        } else if (period == GoalPeriod.yearly) {
          // 设置年度目标时，自动计算月度目标
          final monthlyTarget = targetAmount / 12;

          // 检查是否已有当前月度目标
          final now = DateTime.now();
          final existingMonthlyGoal = await repository.getCurrentGoal(
            userId: authState.user!.id,
            type: type,
            period: GoalPeriod.monthly,
            year: year,
            month: now.month,
          );

          if (existingMonthlyGoal == null) {
            await repository.setOrUpdateGoal(
              userId: authState.user!.id,
              type: type,
              period: GoalPeriod.monthly,
              year: year,
              month: now.month,
              targetAmount: monthlyTarget,
              description: description != null ? '基于年度目标自动计算: $description' : '基于年度目标自动计算',
            );
          }
        }
      }

      // 刷新所有相关的provider
      ref.invalidateSelf();
      ref.invalidate(currentMonthlyGoalProvider);
      ref.invalidate(currentYearlyGoalProvider);
      ref.invalidate(monthlyGoalProgressProvider);
      ref.invalidate(yearlyGoalProgressProvider);
    }, '正在保存目标...');
  }

  Future<void> deleteGoal(String goalId) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(investmentGoalRepositoryProvider);
      await repository.deleteGoal(goalId);
      ref.invalidateSelf();
    }, '正在删除目标...');
  }
}

// Current goal providers
@riverpod
Future<InvestmentGoal?> currentMonthlyGoal(CurrentMonthlyGoalRef ref) async {
  final authState = ref.watch(authServiceProvider);
  if (authState.user == null) return null;

  final now = DateTime.now();
  final repository = ref.watch(investmentGoalRepositoryProvider);

  return await repository.getCurrentGoal(
    userId: authState.user!.id,
    type: GoalType.profit,
    period: GoalPeriod.monthly,
    year: now.year,
    month: now.month,
  );
}

@riverpod
Future<InvestmentGoal?> currentYearlyGoal(CurrentYearlyGoalRef ref) async {
  final authState = ref.watch(authServiceProvider);
  if (authState.user == null) return null;

  final now = DateTime.now();
  final repository = ref.watch(investmentGoalRepositoryProvider);

  return await repository.getCurrentGoal(
    userId: authState.user!.id,
    type: GoalType.profit,
    period: GoalPeriod.yearly,
    year: now.year,
  );
}

// Goal progress providers
@riverpod
Future<Map<String, dynamic>> monthlyGoalProgress(MonthlyGoalProgressRef ref) async {
  final authState = ref.watch(authServiceProvider);
  if (authState.user == null) return _emptyProgress();

  final goal = await ref.watch(currentMonthlyGoalProvider.future);
  if (goal == null) return _emptyProgress();

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final currentStats = await transactionRepository.getTransactionStatsByDateRange(
    userId: authState.user!.id,
    startDate: startOfMonth,
    endDate: endOfMonth,
  );

  // 获取去年同月数据用于同比
  final lastYearStart = DateTime(now.year - 1, now.month, 1);
  final lastYearEnd = DateTime(now.year - 1, now.month + 1, 0, 23, 59, 59);
  final lastYearStats = await transactionRepository.getTransactionStatsByDateRange(
    userId: authState.user!.id,
    startDate: lastYearStart,
    endDate: lastYearEnd,
  );

  return _calculateGoalProgress(goal, currentStats, lastYearStats, now.day, _getDaysInMonth(now.year, now.month));
}

@riverpod
Future<Map<String, dynamic>> yearlyGoalProgress(YearlyGoalProgressRef ref) async {
  final authState = ref.watch(authServiceProvider);
  if (authState.user == null) return _emptyProgress();

  final goal = await ref.watch(currentYearlyGoalProvider.future);
  if (goal == null) return _emptyProgress();

  final now = DateTime.now();
  final startOfYear = DateTime(now.year, 1, 1);
  final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final currentStats = await transactionRepository.getTransactionStatsByDateRange(
    userId: authState.user!.id,
    startDate: startOfYear,
    endDate: endOfYear,
  );

  // 获取去年数据用于同比
  final lastYearStart = DateTime(now.year - 1, 1, 1);
  final lastYearEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
  final lastYearStats = await transactionRepository.getTransactionStatsByDateRange(
    userId: authState.user!.id,
    startDate: lastYearStart,
    endDate: lastYearEnd,
  );

  final dayOfYear = now.difference(startOfYear).inDays + 1;
  final totalDaysInYear = _isLeapYear(now.year) ? 366 : 365;

  return _calculateGoalProgress(goal, currentStats, lastYearStats, dayOfYear, totalDaysInYear);
}

// Helper functions
Map<String, dynamic> _emptyProgress() {
  return {
    'hasGoal': false,
    'targetAmount': 0.0,
    'actualAmount': 0.0,
    'completionRate': 0.0,
    'timeProgress': 0.0,
    'progressRatio': 0.0,
    'status': 'no_goal',
    'lastYearComparison': 0.0,
  };
}

Map<String, dynamic> _calculateGoalProgress(
  InvestmentGoal goal,
  Map<String, dynamic> currentStats,
  Map<String, dynamic> lastYearStats,
  int currentDay,
  int totalDays,
) {
  final targetAmount = goal.targetAmount.toDouble();
  final actualAmount = currentStats['netProfit'] as double;
  final completionRate = targetAmount > 0 ? (actualAmount / targetAmount) * 100 : 0.0;
  final timeProgress = (currentDay / totalDays) * 100;
  final progressRatio = timeProgress > 0 ? completionRate / timeProgress : 0.0;

  String status;
  if (progressRatio > 1.2) {
    status = 'conservative'; // 过于保守
  } else if (progressRatio < 0.8) {
    status = 'aggressive'; // 过于激进
  } else {
    status = 'reasonable'; // 合理
  }

  final lastYearAmount = lastYearStats['netProfit'] as double;
  final lastYearComparison = lastYearAmount != 0
      ? ((actualAmount - lastYearAmount) / lastYearAmount.abs()) * 100
      : 0.0;

  return {
    'hasGoal': true,
    'targetAmount': targetAmount,
    'actualAmount': actualAmount,
    'completionRate': completionRate,
    'timeProgress': timeProgress,
    'progressRatio': progressRatio,
    'status': status,
    'lastYearComparison': lastYearComparison,
  };
}

int _getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

bool _isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}
