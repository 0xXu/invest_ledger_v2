import '../models/transaction.dart';
import '../datasources/local/transaction_dao.dart';

class TransactionRepository {
  final TransactionDao _transactionDao;

  TransactionRepository(this._transactionDao);

  Future<String> addTransaction(Transaction transaction) async {
    return await _transactionDao.createTransaction(transaction);
  }

  Future<Transaction?> getTransactionById(String id) async {
    return await _transactionDao.getTransactionById(id);
  }

  Future<List<Transaction>> getTransactionsByUserId(String userId) async {
    return await _transactionDao.getTransactionsByUserId(userId);
  }

  Future<List<Transaction>> getTransactionsByStockCode(String stockCode) async {
    return await _transactionDao.getTransactionsByStockCode(stockCode);
  }

  Future<List<Transaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _transactionDao.getTransactionsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Transaction>> getAllTransactions() async {
    return await _transactionDao.getAllTransactions();
  }

  Future<List<Transaction>> getTransactionsBySharedInvestmentId(String sharedInvestmentId) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => t.sharedInvestmentId == sharedInvestmentId).toList();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionDao.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionDao.deleteTransaction(id);
  }

  // 统计方法
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    final transactions = await getTransactionsByUserId(userId);

    if (transactions.isEmpty) {
      return {
        'totalInvestment': 0.0,
        'totalProfit': 0.0,
        'totalLoss': 0.0,
        'netProfit': 0.0,
        'transactionCount': 0,
        'profitableTransactions': 0,
        'lossTransactions': 0,
        'winRate': 0.0,
        'profitLossRatio': 0.0,
        'roi': 0.0,
        'uniqueStocks': 0,
      };
    }

    double totalInvestment = 0.0;
    double totalProfitAmount = 0.0; // 所有正收益之和
    double totalLossAmount = 0.0;   // 所有负收益之和（绝对值）
    int profitableTransactions = 0;
    int lossTransactions = 0;

    for (final transaction in transactions) {
      final investment = (transaction.amount * transaction.unitPrice).toDouble();
      totalInvestment += investment;

      final profit = transaction.profitLoss.toDouble();

      if (profit > 0) {
        totalProfitAmount += profit;
        profitableTransactions++;
      } else if (profit < 0) {
        totalLossAmount += profit.abs(); // 存储为正值
        lossTransactions++;
      }
    }

    final netProfit = totalProfitAmount - totalLossAmount;
    final totalTransactions = transactions.length;
    final winRate = totalTransactions > 0 ? (profitableTransactions / totalTransactions) * 100 : 0.0;

    // 计算盈亏比（平均盈利/平均亏损）
    final avgProfit = profitableTransactions > 0 ? totalProfitAmount / profitableTransactions : 0.0;
    final avgLoss = lossTransactions > 0 ? totalLossAmount / lossTransactions : 0.0;
    final profitLossRatio = avgLoss > 0 ? avgProfit / avgLoss : 0.0;

    // 计算ROI
    final roi = totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0.0;

    // 计算唯一股票数量
    final uniqueStocks = transactions.map((t) => t.stockCode).toSet().length;

    return {
      'totalInvestment': totalInvestment,
      'totalProfit': totalProfitAmount,
      'totalLoss': totalLossAmount,
      'netProfit': netProfit,
      'transactionCount': totalTransactions,
      'profitableTransactions': profitableTransactions,
      'lossTransactions': lossTransactions,
      'winRate': winRate,
      'profitLossRatio': profitLossRatio,
      'roi': roi,
      'uniqueStocks': uniqueStocks,
    };
  }

  // 按时间范围获取统计数据
  Future<Map<String, dynamic>> getTransactionStatsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await getTransactionsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    if (transactions.isEmpty) {
      return {
        'totalInvestment': 0.0,
        'totalProfit': 0.0,
        'totalLoss': 0.0,
        'netProfit': 0.0,
        'transactionCount': 0,
        'profitableTransactions': 0,
        'lossTransactions': 0,
        'winRate': 0.0,
        'profitLossRatio': 0.0,
        'roi': 0.0,
      };
    }

    double totalInvestment = 0.0;
    double totalProfitAmount = 0.0;
    double totalLossAmount = 0.0;
    int profitableTransactions = 0;
    int lossTransactions = 0;

    for (final transaction in transactions) {
      final investment = (transaction.amount * transaction.unitPrice).toDouble();
      totalInvestment += investment;

      final profit = transaction.profitLoss.toDouble();

      if (profit > 0) {
        totalProfitAmount += profit;
        profitableTransactions++;
      } else if (profit < 0) {
        totalLossAmount += profit.abs();
        lossTransactions++;
      }
    }

    final netProfit = totalProfitAmount - totalLossAmount;
    final totalTransactions = transactions.length;
    final winRate = totalTransactions > 0 ? (profitableTransactions / totalTransactions) * 100 : 0.0;

    final avgProfit = profitableTransactions > 0 ? totalProfitAmount / profitableTransactions : 0.0;
    final avgLoss = lossTransactions > 0 ? totalLossAmount / lossTransactions : 0.0;
    final profitLossRatio = avgLoss > 0 ? avgProfit / avgLoss : 0.0;

    final roi = totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0.0;

    return {
      'totalInvestment': totalInvestment,
      'totalProfit': totalProfitAmount,
      'totalLoss': totalLossAmount,
      'netProfit': netProfit,
      'transactionCount': totalTransactions,
      'profitableTransactions': profitableTransactions,
      'lossTransactions': lossTransactions,
      'winRate': winRate,
      'profitLossRatio': profitLossRatio,
      'roi': roi,
    };
  }
}
