import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 缓存数据项
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl; // Time to live

  CachedData(this.data, this.timestamp, this.ttl);

  /// 检查缓存是否过期
  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  /// 检查缓存是否仍然有效
  bool get isValid => !isExpired;
}

/// 数据缓存管理器
class DataCacheManager {
  static final Map<String, CachedData> _cache = {};
  static final Map<String, Timer> _timers = {};

  /// 默认缓存时间
  static const Duration defaultTTL = Duration(minutes: 5);
  static const Duration shortTTL = Duration(minutes: 1);
  static const Duration longTTL = Duration(minutes: 15);

  /// 获取缓存数据
  static T? getCached<T>(String key) {
    final cached = _cache[key];
    if (cached != null && cached.isValid) {
      return cached.data as T?;
    }
    // 如果缓存过期，自动清理
    if (cached != null && cached.isExpired) {
      remove(key);
    }
    return null;
  }

  /// 设置缓存数据
  static void cache<T>(
    String key, 
    T data, {
    Duration? ttl,
  }) {
    final effectiveTTL = ttl ?? defaultTTL;
    _cache[key] = CachedData(data, DateTime.now(), effectiveTTL);
    
    // 设置自动清理定时器
    _timers[key]?.cancel();
    _timers[key] = Timer(effectiveTTL, () => remove(key));
  }

  /// 移除缓存
  static void remove(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// 清空所有缓存
  static void clearAll() {
    _cache.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// 清理过期缓存
  static void cleanupExpired() {
    final expiredKeys = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      remove(key);
    }
  }

  /// 获取缓存统计信息
  static Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int validCount = 0;
    int expiredCount = 0;
    
    for (final cached in _cache.values) {
      if (cached.isValid) {
        validCount++;
      } else {
        expiredCount++;
      }
    }

    return {
      'totalItems': _cache.length,
      'validItems': validCount,
      'expiredItems': expiredCount,
      'timersActive': _timers.length,
    };
  }
}

/// 缓存键常量
class CacheKeys {
  static const String transactions = 'transactions';
  static const String transactionStats = 'transaction_stats';
  static const String monthlyGoalProgress = 'monthly_goal_progress';
  static const String yearlyGoalProgress = 'yearly_goal_progress';
  static const String profitLossColors = 'profit_loss_colors';
  static const String userProfile = 'user_profile';
  
  /// 生成带参数的缓存键
  static String transactionById(String id) => 'transaction_$id';
  static String transactionsByStock(String stockCode) => 'transactions_stock_$stockCode';
  static String transactionsByDateRange(String start, String end) => 'transactions_${start}_$end';
}

/// 智能缓存策略
class CacheStrategy {
  /// 根据数据类型选择合适的TTL
  static Duration getTTLForDataType(String dataType) {
    switch (dataType) {
      case CacheKeys.transactions:
        return DataCacheManager.defaultTTL; // 5分钟
      case CacheKeys.transactionStats:
        return DataCacheManager.defaultTTL; // 5分钟
      case CacheKeys.profitLossColors:
        return DataCacheManager.longTTL; // 15分钟，设置变化不频繁
      case CacheKeys.userProfile:
        return DataCacheManager.longTTL; // 15分钟
      default:
        return DataCacheManager.defaultTTL;
    }
  }

  /// 检查是否应该缓存该数据类型
  static bool shouldCache(String dataType) {
    // 某些实时性要求很高的数据可能不适合缓存
    const nonCacheableTypes = <String>[
      // 可以在这里添加不应该缓存的数据类型
    ];
    return !nonCacheableTypes.contains(dataType);
  }
}

/// 缓存装饰器 - 用于Provider
mixin CacheableMixin<T> on AutoDisposeAsyncNotifier<T> {
  String get cacheKey;
  
  @override
  Future<T> build() async {
    // 尝试从缓存获取数据
    final cached = DataCacheManager.getCached<T>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // 缓存未命中，获取新数据
    final data = await fetchData();
    
    // 缓存新数据
    final ttl = CacheStrategy.getTTLForDataType(cacheKey);
    if (CacheStrategy.shouldCache(cacheKey)) {
      DataCacheManager.cache(cacheKey, data, ttl: ttl);
    }
    
    return data;
  }
  
  /// 子类需要实现的数据获取方法
  Future<T> fetchData();
  
  /// 强制刷新数据（绕过缓存）
  Future<void> forceRefresh() async {
    DataCacheManager.remove(cacheKey);
    ref.invalidateSelf();
  }
}

/// 预加载管理器
class PreloadManager {
  static final Set<String> _preloadedKeys = {};
  
  /// 预加载关键数据
  static Future<void> preloadEssentialData(WidgetRef ref) async {
    final futures = <Future>[];
    
    // 预加载交易数据
    if (!_preloadedKeys.contains(CacheKeys.transactions)) {
      futures.add(_preloadTransactions(ref));
      _preloadedKeys.add(CacheKeys.transactions);
    }
    
    // 预加载统计数据
    if (!_preloadedKeys.contains(CacheKeys.transactionStats)) {
      futures.add(_preloadStats(ref));
      _preloadedKeys.add(CacheKeys.transactionStats);
    }
    
    await Future.wait(futures);
  }
  
  static Future<void> _preloadTransactions(WidgetRef ref) async {
    try {
      // 这里可以预加载交易数据
      // ref.read(transactionNotifierProvider.future);
    } catch (e) {
      // 预加载失败不影响主流程
    }
  }
  
  static Future<void> _preloadStats(WidgetRef ref) async {
    try {
      // 这里可以预加载统计数据
      // ref.read(transactionStatsProvider.future);
    } catch (e) {
      // 预加载失败不影响主流程
    }
  }
  
  /// 清理预加载标记
  static void clearPreloadFlags() {
    _preloadedKeys.clear();
  }
}
