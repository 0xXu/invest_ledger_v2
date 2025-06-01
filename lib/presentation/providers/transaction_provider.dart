import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/datasources/local/transaction_dao.dart';
import 'user_provider.dart';
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
    final user = ref.watch(userProvider);
    if (user == null) return [];

    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactionsByUserId(user.id);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);
      ref.invalidateSelf();
    }, '正在添加交易...');
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.updateTransaction(transaction);
      ref.invalidateSelf();
    }, '正在更新交易...');
  }

  Future<void> deleteTransaction(String transactionId) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(transactionId);
      ref.invalidateSelf();
    }, '正在删除交易...');
  }
}

// Transaction stats provider
@riverpod
Future<Map<String, dynamic>> transactionStats(TransactionStatsRef ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    return {
      'totalInvestment': 0.0,
      'totalProfit': 0.0,
      'totalTransactions': 0,
      'profitableTransactions': 0,
      'lossTransactions': 0,
    };
  }

  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionStats(user.id);
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
  TransactionsByDateRangeRef ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByDateRange(
    userId: user.id,
    startDate: startDate,
    endDate: endDate,
  );
}


