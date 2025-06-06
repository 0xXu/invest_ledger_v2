import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../presentation/providers/transaction_provider.dart';

/// 股票历史记录项
class StockHistoryItem {
  final String stockCode;
  final String stockName;
  final DateTime lastUsed;

  const StockHistoryItem({
    required this.stockCode,
    required this.stockName,
    required this.lastUsed,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockHistoryItem &&
          runtimeType == other.runtimeType &&
          stockCode == other.stockCode &&
          stockName == other.stockName;

  @override
  int get hashCode => stockCode.hashCode ^ stockName.hashCode;
}

/// 股票历史记录服务
class StockHistoryService {
  final Ref ref;

  StockHistoryService(this.ref);

  /// 获取股票历史记录
  Future<List<StockHistoryItem>> getStockHistory() async {
    try {
      final transactionsAsync = ref.read(transactionNotifierProvider);
      
      return transactionsAsync.when(
        data: (transactions) => _extractStockHistory(transactions),
        loading: () => <StockHistoryItem>[],
        error: (_, __) => <StockHistoryItem>[],
      );
    } catch (e) {
      return <StockHistoryItem>[];
    }
  }

  /// 从交易记录中提取股票历史
  List<StockHistoryItem> _extractStockHistory(List<Transaction> transactions) {
    final Map<String, StockHistoryItem> stockMap = {};

    for (final transaction in transactions) {
      final key = '${transaction.stockCode}_${transaction.stockName}';
      
      if (!stockMap.containsKey(key) || 
          transaction.createdAt.isAfter(stockMap[key]!.lastUsed)) {
        stockMap[key] = StockHistoryItem(
          stockCode: transaction.stockCode,
          stockName: transaction.stockName,
          lastUsed: transaction.createdAt,
        );
      }
    }

    // 按最后使用时间排序，最近使用的在前
    final items = stockMap.values.toList();
    items.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    
    return items;
  }

  /// 根据股票名称搜索历史记录
  Future<List<StockHistoryItem>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];
    
    final history = await getStockHistory();
    final lowerQuery = query.toLowerCase().trim();
    
    return history.where((item) => 
      item.stockName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// 根据股票代码搜索历史记录
  Future<List<StockHistoryItem>> searchByCode(String query) async {
    if (query.trim().isEmpty) return [];
    
    final history = await getStockHistory();
    final upperQuery = query.toUpperCase().trim();
    
    return history.where((item) => 
      item.stockCode.toUpperCase().contains(upperQuery)
    ).toList();
  }

  /// 根据股票名称查找对应的股票代码
  Future<String?> findCodeByName(String stockName) async {
    if (stockName.trim().isEmpty) return null;
    
    final history = await getStockHistory();
    
    for (final item in history) {
      if (item.stockName == stockName.trim()) {
        return item.stockCode;
      }
    }
    
    return null;
  }

  /// 根据股票代码查找对应的股票名称
  Future<String?> findNameByCode(String stockCode) async {
    if (stockCode.trim().isEmpty) return null;
    
    final history = await getStockHistory();
    
    for (final item in history) {
      if (item.stockCode.toUpperCase() == stockCode.trim().toUpperCase()) {
        return item.stockName;
      }
    }
    
    return null;
  }
}

/// 股票历史记录服务提供者
final stockHistoryServiceProvider = Provider<StockHistoryService>((ref) {
  return StockHistoryService(ref);
});

/// 股票历史记录状态提供者
final stockHistoryProvider = FutureProvider<List<StockHistoryItem>>((ref) async {
  final service = ref.read(stockHistoryServiceProvider);
  return service.getStockHistory();
});

/// 股票名称搜索提供者
final stockNameSearchProvider = FutureProvider.family<List<StockHistoryItem>, String>((ref, query) async {
  final service = ref.read(stockHistoryServiceProvider);
  return service.searchByName(query);
});

/// 股票代码搜索提供者
final stockCodeSearchProvider = FutureProvider.family<List<StockHistoryItem>, String>((ref, query) async {
  final service = ref.read(stockHistoryServiceProvider);
  return service.searchByCode(query);
});
