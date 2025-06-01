import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 性能监控工具
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _measurements = {};
  static bool _isEnabled = kDebugMode;

  /// 启用/禁用性能监控
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 开始测量
  static void startMeasurement(String name) {
    if (!_isEnabled) return;
    _startTimes[name] = DateTime.now();
  }

  /// 结束测量并记录结果
  static Duration? endMeasurement(String name) {
    if (!_isEnabled) return null;
    
    final startTime = _startTimes[name];
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(name);

    // 记录测量结果
    _measurements.putIfAbsent(name, () => []).add(duration);
    
    // 在调试模式下输出结果
    if (kDebugMode) {
      developer.log(
        'Performance: $name took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
      );
    }

    return duration;
  }

  /// 获取平均性能数据
  static Map<String, Duration> getAveragePerformance() {
    final averages = <String, Duration>{};
    
    for (final entry in _measurements.entries) {
      final measurements = entry.value;
      if (measurements.isNotEmpty) {
        final totalMs = measurements
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b);
        final averageMs = totalMs / measurements.length;
        averages[entry.key] = Duration(milliseconds: averageMs.round());
      }
    }
    
    return averages;
  }

  /// 获取详细性能报告
  static Map<String, Map<String, dynamic>> getDetailedReport() {
    final report = <String, Map<String, dynamic>>{};
    
    for (final entry in _measurements.entries) {
      final measurements = entry.value;
      if (measurements.isNotEmpty) {
        final durations = measurements.map((d) => d.inMilliseconds).toList();
        durations.sort();
        
        final count = durations.length;
        final sum = durations.reduce((a, b) => a + b);
        final average = sum / count;
        final min = durations.first;
        final max = durations.last;
        final median = count % 2 == 0
            ? (durations[count ~/ 2 - 1] + durations[count ~/ 2]) / 2
            : durations[count ~/ 2].toDouble();

        report[entry.key] = {
          'count': count,
          'average': average.round(),
          'min': min,
          'max': max,
          'median': median.round(),
          'total': sum,
        };
      }
    }
    
    return report;
  }

  /// 清除所有测量数据
  static void clearMeasurements() {
    _startTimes.clear();
    _measurements.clear();
  }

  /// 打印性能报告
  static void printReport() {
    if (!_isEnabled) return;
    
    final report = getDetailedReport();
    if (report.isEmpty) {
      developer.log('No performance data available', name: 'PerformanceMonitor');
      return;
    }

    developer.log('=== Performance Report ===', name: 'PerformanceMonitor');
    for (final entry in report.entries) {
      final stats = entry.value;
      developer.log(
        '${entry.key}: avg=${stats['average']}ms, min=${stats['min']}ms, max=${stats['max']}ms, count=${stats['count']}',
        name: 'PerformanceMonitor',
      );
    }
    developer.log('========================', name: 'PerformanceMonitor');
  }
}

/// 页面切换性能监控器
class PageTransitionMonitor {
  static const String _pageTransitionKey = 'page_transition';
  static String? _currentPage;

  /// 开始监控页面切换
  static void startPageTransition(String fromPage, String toPage) {
    _currentPage = toPage;
    PerformanceMonitor.startMeasurement('${_pageTransitionKey}_${fromPage}_to_$toPage');
    PerformanceMonitor.startMeasurement('${_pageTransitionKey}_any');
  }

  /// 结束页面切换监控
  static void endPageTransition(String toPage) {
    if (_currentPage == toPage) {
      PerformanceMonitor.endMeasurement('${_pageTransitionKey}_any');
      // 尝试结束具体的页面切换测量
      final measurements = PerformanceMonitor._startTimes.keys
          .where((key) => key.contains('_to_$toPage'))
          .toList();
      for (final key in measurements) {
        PerformanceMonitor.endMeasurement(key);
      }
    }
  }

  /// 获取页面切换性能统计
  static Map<String, Duration> getPageTransitionStats() {
    final allStats = PerformanceMonitor.getAveragePerformance();
    return Map.fromEntries(
      allStats.entries.where((entry) => entry.key.contains(_pageTransitionKey)),
    );
  }
}

/// 性能监控Widget包装器
class PerformanceWrapper extends StatefulWidget {
  final Widget child;
  final String name;
  final bool measureBuild;
  final bool measureLayout;

  const PerformanceWrapper({
    super.key,
    required this.child,
    required this.name,
    this.measureBuild = true,
    this.measureLayout = false,
  });

  @override
  State<PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<PerformanceWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.measureBuild) {
      PerformanceMonitor.startMeasurement('${widget.name}_init');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.measureBuild) {
      PerformanceMonitor.startMeasurement('${widget.name}_build');
    }

    final child = widget.child;

    if (widget.measureBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceMonitor.endMeasurement('${widget.name}_build');
        PerformanceMonitor.endMeasurement('${widget.name}_init');
      });
    }

    if (widget.measureLayout) {
      return LayoutBuilder(
        builder: (context, constraints) {
          PerformanceMonitor.startMeasurement('${widget.name}_layout');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            PerformanceMonitor.endMeasurement('${widget.name}_layout');
          });
          return child;
        },
      );
    }

    return child;
  }
}

/// 性能监控路由观察器
class PerformanceRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(previousRoute?.settings.name, route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _handleRouteChange(route.settings.name, previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _handleRouteChange(oldRoute?.settings.name, newRoute?.settings.name);
  }

  void _handleRouteChange(String? fromRoute, String? toRoute) {
    if (fromRoute != null && toRoute != null) {
      PageTransitionMonitor.startPageTransition(fromRoute, toRoute);
      
      // 延迟一帧后结束测量，确保页面已经完全渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          PageTransitionMonitor.endPageTransition(toRoute);
        });
      });
    }
  }
}

/// 性能优化建议生成器
class PerformanceAnalyzer {
  /// 分析性能数据并生成建议
  static List<String> analyzeAndSuggest() {
    final suggestions = <String>[];
    final report = PerformanceMonitor.getDetailedReport();
    
    for (final entry in report.entries) {
      final name = entry.key;
      final stats = entry.value;
      final average = stats['average'] as int;
      final max = stats['max'] as int;
      
      // 页面切换性能分析
      if (name.contains('page_transition')) {
        if (average > 300) {
          suggestions.add('页面切换平均耗时${average}ms，建议优化页面加载逻辑');
        }
        if (max > 1000) {
          suggestions.add('页面切换最大耗时${max}ms，存在严重性能问题');
        }
      }
      
      // 构建性能分析
      if (name.contains('_build')) {
        if (average > 100) {
          suggestions.add('$name 构建耗时${average}ms，建议优化Widget结构');
        }
      }
      
      // 布局性能分析
      if (name.contains('_layout')) {
        if (average > 50) {
          suggestions.add('$name 布局耗时${average}ms，建议简化布局结构');
        }
      }
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('性能表现良好，无需特别优化');
    }
    
    return suggestions;
  }
}
