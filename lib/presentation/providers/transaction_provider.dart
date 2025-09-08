import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/datasources/local/transaction_dao.dart';
import '../../data/services/transaction_stats_service.dart';
import '../../core/auth/auth_service.dart';
import '../../core/sync/sync_manager.dart';
import 'loading_provider.dart';

part 'transaction_provider.g.dart';

// Repository providers
@riverpod
TransactionDao transactionDao(TransactionDaoRef ref) {
  return TransactionDao();
}

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepository(ref.watch(transactionDaoProvider));
}

// Transaction list provider
@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  @override
  Future<List<Transaction>> build() async {
    final authState = ref.watch(authServiceProvider);
    if (authState.user == null) return [];

    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactionsByUserId(authState.user!.id);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);
      ref.invalidateSelf();

      // 自动触发同步
      _triggerAutoSync();
    }, '正在添加交易...');
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.updateTransaction(transaction);
      ref.invalidateSelf();

      // 自动触发同步
      _triggerAutoSync();
    }, '正在更新交易...');
  }

  Future<void> deleteTransaction(String transactionId) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(transactionId);
      ref.invalidateSelf();

      // 自动触发同步
      _triggerAutoSync();
    }, '正在删除交易...');
  }

  /// 触发自动同步
  void _triggerAutoSync() {
    try {
      final syncManager = ref.read(syncManagerProvider);
      // 异步执行同步，不阻塞当前操作
      Future.microtask(() async {
        try {
          await syncManager.manualSync();
          // 同步完成后刷新数据
          ref.invalidateSelf();
        } catch (e) {
          // 同步失败时不影响用户操作，只是静默处理
          // 可以在这里记录日志或显示非阻塞性提示
        }
      });
    } catch (e) {
      // 如果获取syncManager失败，也不影响用户操作
    }
  }
}

// Transaction stats provider
@riverpod
Future<Map<String, dynamic>> transactionStats(TransactionStatsRef ref) async {
  final authState = ref.watch(authServiceProvider);
  if (authState.user == null) {
    return {
      'totalInvestment': 0.0,
      'totalProfit': 0.0,
      'totalTransactions': 0,
      'profitableTransactions': 0,
      'lossTransactions': 0,
    };
  }

  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionStats(authState.user!.id);
}

// Individual transaction provider
@riverpod
Future<Transaction?> transaction(TransactionRef ref, String transactionId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionById(transactionId);
}

// Transactions by stock code provider
@riverpod
Future<List<Transaction>> transactionsByStock(
  TransactionsByStockRef ref,
  String stockCode,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByStockCode(stockCode);
}

// Transactions by date range provider
@riverpod
Future<List<Transaction>> transactionsByDateRange(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final authState = ref.watch(authServiceProvider);
  if (authState.user == null) return [];

  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByDateRange(
    userId: authState.user!.id,
    startDate: startDate,
    endDate: endDate,
  );
}

// Enhanced stats providers using TransactionStatsService
@riverpod
TransactionStatsService transactionStatsService(Ref ref) {
  return TransactionStatsService();
}

// Comprehensive stats provider
@riverpod
Future<ComprehensiveStats> comprehensiveStats(Ref ref) async {
  final transactions = await ref.watch(transactionNotifierProvider.future);
  final service = ref.watch(transactionStatsServiceProvider);
  return service.calculateComprehensiveStats(transactions);
}

// Filtered transactions provider
@riverpod
class FilteredTransactions extends _$FilteredTransactions {
  @override
  Future<List<Transaction>> build({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stockNames,
    ProfitLossFilter? profitLossFilter,
  }) async {
    final allTransactions = await ref.watch(transactionNotifierProvider.future);
    final service = ref.watch(transactionStatsServiceProvider);
    
    return service.filterTransactions(
      allTransactions,
      startDate: startDate,
      endDate: endDate,
      stockNames: stockNames,
      profitLossFilter: profitLossFilter,
    );
  }
  
  // Update filters method
  void updateFilters({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stockNames,
    ProfitLossFilter? profitLossFilter,
  }) {
    // Invalidate to rebuild with new parameters
    ref.invalidateSelf();
  }
}

// Grouped transactions providers
@riverpod
Future<Map<DateTime, List<Transaction>>> groupedTransactionsByDate(
  Ref ref,
  List<Transaction> transactions,
) async {
  final service = ref.watch(transactionStatsServiceProvider);
  return service.groupTransactionsByDate(transactions);
}

@riverpod
Future<Map<String, List<Transaction>>> groupedTransactionsByStock(
  Ref ref,
  List<Transaction> transactions,
) async {
  final service = ref.watch(transactionStatsServiceProvider);
  return service.groupTransactionsByStock(transactions);
}

// Daily stats provider
@riverpod
Future<DailyStats> dailyStats(
  Ref ref,
  List<Transaction> dayTransactions,
) async {
  final service = ref.watch(transactionStatsServiceProvider);
  return service.calculateDailyStats(dayTransactions);
}

// Quick access providers for common time ranges
@riverpod
Future<List<Transaction>> todayTransactions(Ref ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  
  return ref.watch(transactionsByDateRangeProvider(
    startDate: today,
    endDate: tomorrow,
  ).future);
}

@riverpod
Future<List<Transaction>> thisWeekTransactions(Ref ref) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final weekEnd = weekStartDate.add(const Duration(days: 7));
  
  return ref.watch(transactionsByDateRangeProvider(
    startDate: weekStartDate,
    endDate: weekEnd,
  ).future);
}

@riverpod
Future<List<Transaction>> thisMonthTransactions(Ref ref) async {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  
  return ref.watch(transactionsByDateRangeProvider(
    startDate: monthStart,
    endDate: nextMonth,
  ).future);
}

// Stock names provider for filter dropdowns
@riverpod
Future<List<String>> uniqueStockNames(Ref ref) async {
  final transactions = await ref.watch(transactionNotifierProvider.future);
  final stockNames = transactions.map((t) => t.stockName).toSet().toList();
  stockNames.sort();
  return stockNames;
}


