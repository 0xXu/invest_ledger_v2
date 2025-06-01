import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 优化的图表基类，提供性能优化功能
abstract class OptimizedChartBase extends ConsumerWidget {
  final String title;
  final double? height;
  final bool enableCaching;
  final Duration cacheDuration;

  const OptimizedChartBase({
    super.key,
    required this.title,
    this.height,
    this.enableCaching = true,
    this.cacheDuration = const Duration(minutes: 5),
  });

  /// 构建图表内容
  Widget buildChart(BuildContext context, WidgetRef ref);

  /// 获取缓存键
  String getCacheKey();

  /// 检查数据是否为空
  bool isDataEmpty();

  /// 构建空状态
  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 构建错误状态
  Widget buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 图表内容
            SizedBox(
              height: height ?? 300,
              child: _buildOptimizedChart(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedChart(BuildContext context, WidgetRef ref) {
    try {
      // 检查数据是否为空
      if (isDataEmpty()) {
        return buildEmptyState(context);
      }

      // 使用RepaintBoundary优化重绘性能
      return RepaintBoundary(
        child: _buildCachedChart(context, ref),
      );
    } catch (error) {
      return buildErrorState(context, error);
    }
  }

  Widget _buildCachedChart(BuildContext context, WidgetRef ref) {
    if (!enableCaching) {
      return buildChart(context, ref);
    }

    // 使用缓存提供者
    return Consumer(
      builder: (context, ref, child) {
        final cacheKey = getCacheKey();
        final cachedWidget = ref.watch(_chartCacheProvider(cacheKey));

        return cachedWidget.when(
          data: (widget) => widget ?? _buildAndCacheChart(context, ref, cacheKey),
          loading: () => buildLoadingState(context),
          error: (error, stack) => buildErrorState(context, error),
        );
      },
    );
  }

  Widget _buildAndCacheChart(BuildContext context, WidgetRef ref, String cacheKey) {
    final chart = buildChart(context, ref);
    
    // 缓存图表
    if (enableCaching) {
      ref.read(_chartCacheProvider(cacheKey).notifier).cacheChart(chart, cacheDuration);
    }
    
    return chart;
  }
}

/// 图表缓存提供者
final _chartCacheProvider = StateNotifierProvider.family<ChartCacheNotifier, AsyncValue<Widget?>, String>(
  (ref, cacheKey) => ChartCacheNotifier(),
);

class ChartCacheNotifier extends StateNotifier<AsyncValue<Widget?>> {
  ChartCacheNotifier() : super(const AsyncValue.data(null));

  DateTime? _cacheTime;
  Duration? _cacheDuration;

  void cacheChart(Widget chart, Duration duration) {
    _cacheTime = DateTime.now();
    _cacheDuration = duration;
    state = AsyncValue.data(chart);
  }

  bool get isCacheValid {
    if (_cacheTime == null || _cacheDuration == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration!;
  }

  void invalidateCache() {
    _cacheTime = null;
    _cacheDuration = null;
    state = const AsyncValue.data(null);
  }
}

/// 图表性能监控器
class ChartPerformanceMonitor {
  static final Map<String, List<Duration>> _renderTimes = {};
  static final Map<String, int> _renderCounts = {};

  static void recordRenderTime(String chartType, Duration renderTime) {
    _renderTimes.putIfAbsent(chartType, () => []).add(renderTime);
    _renderCounts[chartType] = (_renderCounts[chartType] ?? 0) + 1;
  }

  static Duration? getAverageRenderTime(String chartType) {
    final times = _renderTimes[chartType];
    if (times == null || times.isEmpty) return null;

    final totalMicroseconds = times.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );

    return Duration(microseconds: totalMicroseconds ~/ times.length);
  }

  static int getRenderCount(String chartType) {
    return _renderCounts[chartType] ?? 0;
  }

  static void clearStats() {
    _renderTimes.clear();
    _renderCounts.clear();
  }

  static Map<String, Map<String, dynamic>> getAllStats() {
    final stats = <String, Map<String, dynamic>>{};

    for (final chartType in _renderTimes.keys) {
      final avgTime = getAverageRenderTime(chartType);
      final count = getRenderCount(chartType);

      stats[chartType] = {
        'averageRenderTime': avgTime?.inMilliseconds,
        'renderCount': count,
        'totalRenders': _renderTimes[chartType]?.length ?? 0,
      };
    }

    return stats;
  }
}

/// 图表数据采样器 - 用于大数据量优化
class ChartDataSampler {
  /// 对数据进行采样以提高性能
  static List<T> sampleData<T>(
    List<T> data, {
    int maxPoints = 100,
    SamplingStrategy strategy = SamplingStrategy.uniform,
  }) {
    if (data.length <= maxPoints) {
      return data;
    }

    switch (strategy) {
      case SamplingStrategy.uniform:
        return _uniformSampling(data, maxPoints);
      case SamplingStrategy.adaptive:
        return _adaptiveSampling(data, maxPoints);
    }
  }

  static List<T> _uniformSampling<T>(List<T> data, int maxPoints) {
    final step = data.length / maxPoints;
    final sampled = <T>[];

    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).round();
      if (index < data.length) {
        sampled.add(data[index]);
      }
    }

    return sampled;
  }

  static List<T> _adaptiveSampling<T>(List<T> data, int maxPoints) {
    // 简化的自适应采样 - 保留首尾和关键点
    if (data.length <= maxPoints) return data;

    final sampled = <T>[];
    final step = data.length / maxPoints;

    // 添加第一个点
    sampled.add(data.first);

    // 添加中间点
    for (int i = 1; i < maxPoints - 1; i++) {
      final index = (i * step).round();
      if (index < data.length) {
        sampled.add(data[index]);
      }
    }

    // 添加最后一个点
    if (data.length > 1) {
      sampled.add(data.last);
    }

    return sampled;
  }
}

enum SamplingStrategy {
  uniform,
  adaptive,
}
