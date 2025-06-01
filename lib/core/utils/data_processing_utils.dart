import 'dart:async';
import 'dart:isolate';
import 'dart:math';

/// 大数据量处理优化工具类
class DataProcessingUtils {
  static const int _defaultChunkSize = 1000;
  static const int _isolateThreshold = 5000;

  /// 分块处理大数据集
  static Future<List<R>> processInChunks<T, R>(
    List<T> data,
    R Function(T) processor, {
    int chunkSize = _defaultChunkSize,
    bool useIsolate = false,
  }) async {
    if (data.isEmpty) return [];

    // 如果数据量小，直接处理
    if (data.length < chunkSize && !useIsolate) {
      return data.map(processor).toList();
    }

    final results = <R>[];
    final chunks = _createChunks(data, chunkSize);

    for (final chunk in chunks) {
      if (useIsolate && chunk.length > _isolateThreshold) {
        final chunkResults = await _processChunkInIsolate(chunk, processor);
        results.addAll(chunkResults);
      } else {
        final chunkResults = chunk.map(processor).toList();
        results.addAll(chunkResults);
      }

      // 让出控制权，避免阻塞UI
      await Future.delayed(Duration.zero);
    }

    return results;
  }

  /// 异步流式处理大数据集
  static Stream<R> processAsStream<T, R>(
    List<T> data,
    R Function(T) processor, {
    int chunkSize = _defaultChunkSize,
  }) async* {
    if (data.isEmpty) return;

    final chunks = _createChunks(data, chunkSize);

    for (final chunk in chunks) {
      for (final item in chunk) {
        yield processor(item);
      }
      
      // 让出控制权
      await Future.delayed(Duration.zero);
    }
  }

  /// 并行处理数据
  static Future<List<R>> processInParallel<T, R>(
    List<T> data,
    Future<R> Function(T) processor, {
    int concurrency = 4,
  }) async {
    if (data.isEmpty) return [];

    final chunks = _createChunks(data, (data.length / concurrency).ceil());
    final futures = chunks.map((chunk) async {
      final results = <R>[];
      for (final item in chunk) {
        results.add(await processor(item));
      }
      return results;
    });

    final chunkResults = await Future.wait(futures);
    return chunkResults.expand((chunk) => chunk).toList();
  }

  /// 创建数据分块
  static List<List<T>> _createChunks<T>(List<T> data, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = min(i + chunkSize, data.length);
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  /// 在Isolate中处理数据块
  static Future<List<R>> _processChunkInIsolate<T, R>(
    List<T> chunk,
    R Function(T) processor,
  ) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntryPoint<T, R>,
      _IsolateMessage(chunk, processor, receivePort.sendPort),
    );

    final results = await receivePort.first as List<R>;
    isolate.kill();
    receivePort.close();

    return results;
  }

  /// Isolate入口点
  static void _isolateEntryPoint<T, R>(_IsolateMessage<T, R> message) {
    final results = message.data.map(message.processor).toList();
    message.sendPort.send(results);
  }
}

/// Isolate消息类
class _IsolateMessage<T, R> {
  final List<T> data;
  final R Function(T) processor;
  final SendPort sendPort;

  _IsolateMessage(this.data, this.processor, this.sendPort);
}

/// 内存优化的数据缓存
class OptimizedDataCache<K, V> {
  final int _maxSize;
  final Duration _ttl;
  final Map<K, _CacheEntry<V>> _cache = {};
  final List<K> _accessOrder = [];

  OptimizedDataCache({
    int maxSize = 100,
    Duration ttl = const Duration(minutes: 10),
  })  : _maxSize = maxSize,
        _ttl = ttl;

  /// 获取缓存值
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // 检查是否过期
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }

    // 更新访问顺序
    _accessOrder.remove(key);
    _accessOrder.add(key);

    return entry.value;
  }

  /// 设置缓存值
  void set(K key, V value) {
    // 如果已存在，更新值
    if (_cache.containsKey(key)) {
      _cache[key] = _CacheEntry(value, DateTime.now());
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return;
    }

    // 检查缓存大小限制
    if (_cache.length >= _maxSize) {
      _evictLeastRecentlyUsed();
    }

    _cache[key] = _CacheEntry(value, DateTime.now());
    _accessOrder.add(key);
  }

  /// 清除过期条目
  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => now.difference(entry.value.timestamp) > _ttl)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    clearExpired();
    return {
      'size': _cache.length,
      'maxSize': _maxSize,
      'hitRate': _calculateHitRate(),
      'memoryUsage': _estimateMemoryUsage(),
    };
  }

  /// 驱逐最近最少使用的条目
  void _evictLeastRecentlyUsed() {
    if (_accessOrder.isNotEmpty) {
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }
  }

  /// 计算命中率（简化实现）
  double _calculateHitRate() {
    // 这里应该跟踪实际的命中和未命中次数
    return _cache.isNotEmpty ? 0.8 : 0.0;
  }

  /// 估算内存使用量（简化实现）
  int _estimateMemoryUsage() {
    // 简化的内存估算
    return _cache.length * 1024; // 假设每个条目1KB
  }
}

/// 缓存条目
class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// 数据分页器
class DataPaginator<T> {
  final List<T> _data;
  final int _pageSize;
  int _currentPage = 0;

  DataPaginator(this._data, {int pageSize = 50}) : _pageSize = pageSize;

  /// 获取当前页数据
  List<T> getCurrentPage() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = min(startIndex + _pageSize, _data.length);
    
    if (startIndex >= _data.length) return [];
    
    return _data.sublist(startIndex, endIndex);
  }

  /// 下一页
  bool nextPage() {
    if (hasNextPage()) {
      _currentPage++;
      return true;
    }
    return false;
  }

  /// 上一页
  bool previousPage() {
    if (hasPreviousPage()) {
      _currentPage--;
      return true;
    }
    return false;
  }

  /// 跳转到指定页
  bool goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage = page;
      return true;
    }
    return false;
  }

  /// 是否有下一页
  bool hasNextPage() => _currentPage < totalPages - 1;

  /// 是否有上一页
  bool hasPreviousPage() => _currentPage > 0;

  /// 总页数
  int get totalPages => (_data.length / _pageSize).ceil();

  /// 当前页码
  int get currentPage => _currentPage;

  /// 总数据量
  int get totalItems => _data.length;

  /// 当前页数据量
  int get currentPageSize => getCurrentPage().length;
}

/// 性能监控器
class PerformanceMonitor {
  static final Map<String, List<Duration>> _operationTimes = {};
  static final Map<String, int> _operationCounts = {};

  /// 监控操作性能
  static Future<T> monitor<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordOperation(operationName, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperation('${operationName}_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// 记录操作
  static void _recordOperation(String operationName, Duration duration) {
    _operationTimes.putIfAbsent(operationName, () => []).add(duration);
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }

  /// 获取性能统计
  static Map<String, Map<String, dynamic>> getStats() {
    final stats = <String, Map<String, dynamic>>{};

    for (final operation in _operationTimes.keys) {
      final times = _operationTimes[operation]!;
      final count = _operationCounts[operation]!;
      
      final totalTime = times.fold<Duration>(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      
      final avgTime = Duration(
        microseconds: totalTime.inMicroseconds ~/ times.length,
      );

      stats[operation] = {
        'count': count,
        'totalTime': totalTime.inMilliseconds,
        'averageTime': avgTime.inMilliseconds,
        'minTime': times.map((d) => d.inMilliseconds).reduce(min),
        'maxTime': times.map((d) => d.inMilliseconds).reduce(max),
      };
    }

    return stats;
  }

  /// 清除统计数据
  static void clearStats() {
    _operationTimes.clear();
    _operationCounts.clear();
  }
}
