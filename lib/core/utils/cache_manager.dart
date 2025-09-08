import 'dart:async';

/// 应用内存缓存管理器
/// 提供统一的缓存机制，减少重复计算和网络请求
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheItem> _cache = {};
  Timer? _cleanupTimer;

  static const Duration defaultTTL = Duration(minutes: 5);
  static const Duration shortTTL = Duration(minutes: 1);
  static const Duration longTTL = Duration(hours: 1);

  /// 初始化缓存管理器
  void initialize() {
    // 每5分钟清理过期缓存
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanup();
    });
  }

  /// 获取缓存数据
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null || item.isExpired) {
      _cache.remove(key);
      return null;
    }
    return item.value as T?;
  }

  /// 设置缓存数据
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheItem(
      value: value,
      expiredAt: DateTime.now().add(ttl ?? defaultTTL),
    );
  }

  /// 删除指定缓存
  void remove(String key) {
    _cache.remove(key);
  }

  /// 清空所有缓存
  void clear() {
    _cache.clear();
  }

  /// 清理过期缓存
  void _cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, item) => item.expiredAt.isBefore(now));
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final total = _cache.length;
    final expired = _cache.values.where((item) => item.expiredAt.isBefore(now)).length;
    
    return {
      'total': total,
      'active': total - expired,
      'expired': expired,
      'memory_usage': _cache.length * 64, // 估算内存使用
    };
  }

  /// 销毁缓存管理器
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

/// 缓存项
class _CacheItem {
  final dynamic value;
  final DateTime expiredAt;

  _CacheItem({
    required this.value,
    required this.expiredAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiredAt);
}

/// 缓存键常量
class CacheKeys {
  // 用户数据相关
  static const String userTransactions = 'user_transactions';
  static const String transactionStats = 'transaction_stats';
  static const String monthlyGoalProgress = 'monthly_goal_progress';
  static const String yearlyGoalProgress = 'yearly_goal_progress';
  
  // 股票数据相关
  static const String stockSuggestions = 'stock_suggestions';
  static const String stockPrices = 'stock_prices';
  
  // AI分析相关
  static const String aiAnalysis = 'ai_analysis';
  static const String aiSuggestions = 'ai_suggestions';
  
  // 用户偏好设置
  static const String userSettings = 'user_settings';
  static const String colorTheme = 'color_theme';

  /// 生成带用户ID的缓存键
  static String withUserId(String key, String userId) {
    return '${key}_$userId';
  }

  /// 生成带时间范围的缓存键
  static String withTimeRange(String key, String userId, DateTime start, DateTime end) {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    return '${key}_${userId}_${startStr}_$endStr';
  }
}