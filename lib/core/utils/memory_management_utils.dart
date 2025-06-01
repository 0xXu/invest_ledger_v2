import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 内存管理优化工具类
class MemoryManagementUtils {
  static final MemoryManagementUtils _instance = MemoryManagementUtils._internal();
  factory MemoryManagementUtils() => _instance;
  MemoryManagementUtils._internal();

  Timer? _memoryMonitorTimer;
  final List<MemorySnapshot> _memoryHistory = [];
  final Map<String, WeakReference<Object>> _weakReferences = {};

  static const int _maxHistorySize = 100;
  static const Duration _monitorInterval = Duration(seconds: 30);

  /// 开始内存监控
  void startMemoryMonitoring() {
    if (_memoryMonitorTimer?.isActive == true) return;

    _memoryMonitorTimer = Timer.periodic(_monitorInterval, (_) {
      _recordMemorySnapshot();
    });

    if (kDebugMode) {
      developer.log('Memory monitoring started', name: 'MemoryManager');
    }
  }

  /// 停止内存监控
  void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;

    if (kDebugMode) {
      developer.log('Memory monitoring stopped', name: 'MemoryManager');
    }
  }

  /// 记录内存快照
  void _recordMemorySnapshot() {
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      usedMemory: _getCurrentMemoryUsage(),
      objectCount: _getObjectCount(),
    );

    _memoryHistory.add(snapshot);

    // 保持历史记录大小限制
    if (_memoryHistory.length > _maxHistorySize) {
      _memoryHistory.removeAt(0);
    }

    // 检查内存泄漏
    _checkForMemoryLeaks(snapshot);
  }

  /// 获取当前内存使用量（简化实现）
  int _getCurrentMemoryUsage() {
    // 在实际应用中，这里应该使用平台特定的API获取真实内存使用量
    // 这里返回一个模拟值
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  /// 获取对象数量（简化实现）
  int _getObjectCount() {
    return _weakReferences.length;
  }

  /// 检查内存泄漏
  void _checkForMemoryLeaks(MemorySnapshot snapshot) {
    if (_memoryHistory.length < 10) return;

    final recentSnapshots = _memoryHistory.length >= 10
        ? _memoryHistory.sublist(_memoryHistory.length - 10)
        : _memoryHistory;
    final memoryGrowth = recentSnapshots.last.usedMemory - recentSnapshots.first.usedMemory;

    // 如果内存持续增长超过阈值，发出警告
    if (memoryGrowth > 50000) { // 50MB
      if (kDebugMode) {
        developer.log(
          'Potential memory leak detected: ${memoryGrowth}KB growth in last 10 snapshots',
          name: 'MemoryManager',
          level: 900, // Warning level
        );
      }
    }
  }

  /// 强制垃圾回收
  void forceGarbageCollection() {
    // 清理弱引用中的无效对象
    _cleanupWeakReferences();

    // 触发系统垃圾回收
    if (kDebugMode) {
      developer.log('Forced garbage collection', name: 'MemoryManager');
    }
  }

  /// 清理弱引用
  void _cleanupWeakReferences() {
    final keysToRemove = <String>[];

    for (final entry in _weakReferences.entries) {
      if (entry.value.target == null) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _weakReferences.remove(key);
    }
  }

  /// 注册对象用于内存跟踪
  void registerObject(String key, Object object) {
    _weakReferences[key] = WeakReference(object);
  }

  /// 注销对象
  void unregisterObject(String key) {
    _weakReferences.remove(key);
  }

  /// 获取内存统计信息
  MemoryStats getMemoryStats() {
    _cleanupWeakReferences();

    return MemoryStats(
      currentMemoryUsage: _getCurrentMemoryUsage(),
      trackedObjectCount: _weakReferences.length,
      memoryHistory: List.unmodifiable(_memoryHistory),
      averageMemoryUsage: _calculateAverageMemoryUsage(),
      peakMemoryUsage: _calculatePeakMemoryUsage(),
    );
  }

  /// 计算平均内存使用量
  double _calculateAverageMemoryUsage() {
    if (_memoryHistory.isEmpty) return 0.0;

    final total = _memoryHistory.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.usedMemory,
    );

    return total / _memoryHistory.length;
  }

  /// 计算峰值内存使用量
  int _calculatePeakMemoryUsage() {
    if (_memoryHistory.isEmpty) return 0;

    return _memoryHistory
        .map((snapshot) => snapshot.usedMemory)
        .reduce((a, b) => a > b ? a : b);
  }

  /// 清理所有数据
  void dispose() {
    stopMemoryMonitoring();
    _memoryHistory.clear();
    _weakReferences.clear();
  }
}

/// 内存快照
class MemorySnapshot {
  final DateTime timestamp;
  final int usedMemory; // 字节
  final int objectCount;

  const MemorySnapshot({
    required this.timestamp,
    required this.usedMemory,
    required this.objectCount,
  });

  @override
  String toString() {
    return 'MemorySnapshot(timestamp: $timestamp, usedMemory: ${usedMemory}KB, objectCount: $objectCount)';
  }
}

/// 内存统计信息
class MemoryStats {
  final int currentMemoryUsage;
  final int trackedObjectCount;
  final List<MemorySnapshot> memoryHistory;
  final double averageMemoryUsage;
  final int peakMemoryUsage;

  const MemoryStats({
    required this.currentMemoryUsage,
    required this.trackedObjectCount,
    required this.memoryHistory,
    required this.averageMemoryUsage,
    required this.peakMemoryUsage,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentMemoryUsage': currentMemoryUsage,
      'trackedObjectCount': trackedObjectCount,
      'averageMemoryUsage': averageMemoryUsage,
      'peakMemoryUsage': peakMemoryUsage,
      'historySize': memoryHistory.length,
    };
  }
}

/// 内存优化的图片缓存
class OptimizedImageCache {
  static final OptimizedImageCache _instance = OptimizedImageCache._internal();
  factory OptimizedImageCache() => _instance;
  OptimizedImageCache._internal();

  final Map<String, WeakReference<Object>> _imageCache = {};
  static const int _maxCacheSize = 50;

  /// 缓存图片
  void cacheImage(String key, Object image) {
    // 如果缓存已满，清理最旧的条目
    if (_imageCache.length >= _maxCacheSize) {
      _cleanupCache();
    }

    _imageCache[key] = WeakReference(image);
  }

  /// 获取缓存的图片
  Object? getCachedImage(String key) {
    final weakRef = _imageCache[key];
    return weakRef?.target;
  }

  /// 清理缓存
  void _cleanupCache() {
    final keysToRemove = <String>[];

    for (final entry in _imageCache.entries) {
      if (entry.value.target == null) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _imageCache.remove(key);
    }

    // 如果清理后仍然超过限制，移除一些条目
    if (_imageCache.length >= _maxCacheSize) {
      final keys = _imageCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final key in keys) {
        _imageCache.remove(key);
      }
    }
  }

  /// 清空缓存
  void clearCache() {
    _imageCache.clear();
  }

  /// 获取缓存统计
  Map<String, int> getCacheStats() {
    _cleanupCache();
    return {
      'cacheSize': _imageCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }
}

/// 内存优化的列表构建器
class OptimizedListBuilder {
  /// 构建优化的列表视图
  static Widget buildOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    double? itemExtent,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      itemCount: items.length,
      itemExtent: itemExtent,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      // 使用RepaintBoundary优化重绘
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }

  /// 构建分页列表视图
  static Widget buildPaginatedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    int pageSize = 50,
    double? itemExtent,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        int currentPage = 0;
        final totalPages = (items.length / pageSize).ceil();

        List<T> getCurrentPageItems() {
          final startIndex = currentPage * pageSize;
          final endIndex = (startIndex + pageSize).clamp(0, items.length);
          return items.sublist(startIndex, endIndex);
        }

        return Column(
          children: [
            Expanded(
              child: buildOptimizedListView(
                items: getCurrentPageItems(),
                itemBuilder: itemBuilder,
                itemExtent: itemExtent,
                shrinkWrap: shrinkWrap,
                physics: physics,
                padding: padding,
              ),
            ),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPage > 0
                        ? () => setState(() => currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${currentPage + 1} / $totalPages'),
                  IconButton(
                    onPressed: currentPage < totalPages - 1
                        ? () => setState(() => currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// 内存优化的Mixin
mixin MemoryOptimizedMixin {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];

  /// 添加订阅
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// 添加定时器
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// 清理资源
  void disposeMemoryOptimized() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}
