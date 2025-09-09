import '../models/transaction.dart';

/// 交易统计服务 - 提供丰富的数据分析功能
class TransactionStatsService {
  static const TransactionStatsService _instance = TransactionStatsService._internal();
  factory TransactionStatsService() => _instance;
  const TransactionStatsService._internal();

  /// 计算综合统计数据
  ComprehensiveStats calculateComprehensiveStats(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return ComprehensiveStats.empty();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 基础统计
    double totalInvestment = 0.0;
    double totalProfit = 0.0;
    double totalLoss = 0.0;
    int profitableTransactions = 0;
    int lossTransactions = 0;
    
    // 今日统计
    double todayProfit = 0.0;
    int todayTransactions = 0;
    
    // 股票统计
    Map<String, StockStats> stockStats = {};
    
    for (final transaction in transactions) {
      final profitLoss = transaction.profitLoss.toDouble();
      final investment = transaction.amount.toDouble() * transaction.unitPrice.toDouble();
      
      totalInvestment += investment.abs(); // 总投资金额（绝对值）
      
      if (profitLoss > 0) {
        totalProfit += profitLoss;
        profitableTransactions++;
      } else if (profitLoss < 0) {
        totalLoss += profitLoss.abs();
        lossTransactions++;
      }
      
      // 今日数据
      if (transaction.date.isAfter(today) || _isSameDay(transaction.date, today)) {
        todayProfit += profitLoss;
        todayTransactions++;
      }
      
      // 股票统计
      final stockName = transaction.stockName;
      if (stockStats.containsKey(stockName)) {
        stockStats[stockName]!.addTransaction(transaction);
      } else {
        stockStats[stockName] = StockStats.fromTransaction(transaction);
      }
    }
    
    final winRate = transactions.isNotEmpty 
        ? (profitableTransactions / transactions.length) * 100 
        : 0.0;
    
    final roi = totalInvestment > 0 
        ? ((totalProfit - totalLoss) / totalInvestment) * 100 
        : 0.0;

    return ComprehensiveStats(
      totalTransactions: transactions.length,
      totalInvestment: totalInvestment,
      totalProfit: totalProfit,
      totalLoss: totalLoss,
      netProfit: totalProfit - totalLoss,
      profitableTransactions: profitableTransactions,
      lossTransactions: lossTransactions,
      winRate: winRate,
      roi: roi,
      todayProfit: todayProfit,
      todayTransactions: todayTransactions,
      uniqueStocks: stockStats.length,
      stockStats: stockStats,
    );
  }

  /// 按日期分组交易记录
  Map<DateTime, List<Transaction>> groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    final dateOrder = <DateTime>[]; // 保持日期出现的顺序
    
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      if (grouped.containsKey(date)) {
        grouped[date]!.add(transaction);
      } else {
        grouped[date] = [transaction];
        dateOrder.add(date); // 记录日期第一次出现的顺序
      }
    }
    
    // 按照日期在原始交易列表中第一次出现的顺序返回
    return Map.fromEntries(
      dateOrder.map((date) => MapEntry(date, grouped[date]!))
    );
  }

  /// 按股票分组交易记录
  Map<String, List<Transaction>> groupTransactionsByStock(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final stockName = transaction.stockName;
      
      if (grouped.containsKey(stockName)) {
        grouped[stockName]!.add(transaction);
      } else {
        grouped[stockName] = [transaction];
      }
    }
    
    // 按总盈亏排序
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final aTotalProfit = a.value.fold(0.0, (sum, t) => sum + t.profitLoss.toDouble());
        final bTotalProfit = b.value.fold(0.0, (sum, t) => sum + t.profitLoss.toDouble());
        return bTotalProfit.compareTo(aTotalProfit);
      });
    
    return Map.fromEntries(sortedEntries);
  }

  /// 计算每日统计汇总
  DailyStats calculateDailyStats(List<Transaction> dayTransactions) {
    if (dayTransactions.isEmpty) {
      return DailyStats.empty();
    }

    double dailyProfit = 0.0;
    double dailyLoss = 0.0;
    int profitableCount = 0;
    int lossCount = 0;
    
    for (final transaction in dayTransactions) {
      final profitLoss = transaction.profitLoss.toDouble();
      if (profitLoss > 0) {
        dailyProfit += profitLoss;
        profitableCount++;
      } else if (profitLoss < 0) {
        dailyLoss += profitLoss.abs();
        lossCount++;
      }
    }

    return DailyStats(
      date: dayTransactions.first.date,
      transactionCount: dayTransactions.length,
      profit: dailyProfit,
      loss: dailyLoss,
      netProfit: dailyProfit - dailyLoss,
      profitableCount: profitableCount,
      lossCount: lossCount,
    );
  }

  /// 筛选交易记录
  List<Transaction> filterTransactions(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stockNames,
    ProfitLossFilter? profitLossFilter,
  }) {
    return transactions.where((transaction) {
      // 日期筛选
      if (startDate != null && transaction.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && transaction.date.isAfter(endDate)) {
        return false;
      }
      
      // 股票筛选
      if (stockNames != null && stockNames.isNotEmpty) {
        if (!stockNames.contains(transaction.stockName)) {
          return false;
        }
      }
      
      // 盈亏筛选
      if (profitLossFilter != null) {
        final profitLoss = transaction.profitLoss.toDouble();
        switch (profitLossFilter) {
          case ProfitLossFilter.profitOnly:
            if (profitLoss <= 0) return false;
            break;
          case ProfitLossFilter.lossOnly:
            if (profitLoss >= 0) return false;
            break;
          case ProfitLossFilter.all:
            break;
        }
      }
      
      return true;
    }).toList();
  }

  /// 判断是否为同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

/// 盈亏筛选枚举
enum ProfitLossFilter {
  all,      // 全部
  profitOnly, // 仅盈利
  lossOnly,   // 仅亏损
}

/// 综合统计数据
class ComprehensiveStats {
  final int totalTransactions;
  final double totalInvestment;
  final double totalProfit;
  final double totalLoss;
  final double netProfit;
  final int profitableTransactions;
  final int lossTransactions;
  final double winRate;
  final double roi;
  final double todayProfit;
  final int todayTransactions;
  final int uniqueStocks;
  final Map<String, StockStats> stockStats;

  const ComprehensiveStats({
    required this.totalTransactions,
    required this.totalInvestment,
    required this.totalProfit,
    required this.totalLoss,
    required this.netProfit,
    required this.profitableTransactions,
    required this.lossTransactions,
    required this.winRate,
    required this.roi,
    required this.todayProfit,
    required this.todayTransactions,
    required this.uniqueStocks,
    required this.stockStats,
  });

  factory ComprehensiveStats.empty() {
    return const ComprehensiveStats(
      totalTransactions: 0,
      totalInvestment: 0.0,
      totalProfit: 0.0,
      totalLoss: 0.0,
      netProfit: 0.0,
      profitableTransactions: 0,
      lossTransactions: 0,
      winRate: 0.0,
      roi: 0.0,
      todayProfit: 0.0,
      todayTransactions: 0,
      uniqueStocks: 0,
      stockStats: {},
    );
  }
}

/// 单个股票统计数据
class StockStats {
  final String stockName;
  final String stockCode;
  int transactionCount;
  double totalProfit;
  double totalLoss;
  double totalInvestment;

  StockStats({
    required this.stockName,
    required this.stockCode,
    required this.transactionCount,
    required this.totalProfit,
    required this.totalLoss,
    required this.totalInvestment,
  });

  factory StockStats.fromTransaction(Transaction transaction) {
    final profitLoss = transaction.profitLoss.toDouble();
    final investment = transaction.amount.toDouble() * transaction.unitPrice.toDouble();
    
    return StockStats(
      stockName: transaction.stockName,
      stockCode: transaction.stockCode,
      transactionCount: 1,
      totalProfit: profitLoss > 0 ? profitLoss : 0.0,
      totalLoss: profitLoss < 0 ? profitLoss.abs() : 0.0,
      totalInvestment: investment.abs(),
    );
  }

  void addTransaction(Transaction transaction) {
    transactionCount++;
    final profitLoss = transaction.profitLoss.toDouble();
    final investment = transaction.amount.toDouble() * transaction.unitPrice.toDouble();
    
    if (profitLoss > 0) {
      totalProfit += profitLoss;
    } else if (profitLoss < 0) {
      totalLoss += profitLoss.abs();
    }
    
    totalInvestment += investment.abs();
  }

  double get netProfit => totalProfit - totalLoss;
  double get roi => totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0.0;
}

/// 每日统计数据
class DailyStats {
  final DateTime date;
  final int transactionCount;
  final double profit;
  final double loss;
  final double netProfit;
  final int profitableCount;
  final int lossCount;

  const DailyStats({
    required this.date,
    required this.transactionCount,
    required this.profit,
    required this.loss,
    required this.netProfit,
    required this.profitableCount,
    required this.lossCount,
  });

  factory DailyStats.empty() {
    return DailyStats(
      date: DateTime.now(),
      transactionCount: 0,
      profit: 0.0,
      loss: 0.0,
      netProfit: 0.0,
      profitableCount: 0,
      lossCount: 0,
    );
  }
}