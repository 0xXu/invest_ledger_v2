import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/transaction.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../providers/color_theme_provider.dart';

class MonthlyTrendChart extends ConsumerWidget {
  final List<Transaction> transactions;
  final String title;
  final double? height;

  const MonthlyTrendChart({
    super.key,
    required this.transactions,
    required this.title,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.trendingUp,
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
              const SizedBox(height: 24),
              SizedBox(
                height: height ?? 300,
                child: _buildChart(context, colors),
              ),
            ],
          ),
        ),
      ),
      loading: () => Card(
        child: SizedBox(
          height: (height ?? 300) + 80,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: SizedBox(
          height: (height ?? 300) + 80,
          child: const Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, ProfitLossColors colors) {
    final monthlyData = _calculateMonthlyData();

    if (monthlyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.barChart3, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无数据',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final spots = monthlyData.entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value,
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _calculateInterval(monthlyData.values),
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final monthIndex = value.toInt();
                if (monthIndex < 1 || monthIndex > 12) return const Text('');
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '$monthIndex月',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(monthlyData.values),
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatCurrency(value),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 1,
        maxX: 12,
        minY: _calculateMinY(monthlyData.values),
        maxY: _calculateMaxY(monthlyData.values),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colors.getProfitColor(),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final value = spot.y;
                return FlDotCirclePainter(
                  radius: 4,
                  color: value >= 0 ? colors.getProfitColor() : colors.getLossColor(),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colors.getProfitColor().withValues(alpha: 0.3),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final month = barSpot.x.toInt();
                final value = barSpot.y;
                return LineTooltipItem(
                  '$month月\n${_formatCurrency(value)}',
                  TextStyle(
                    color: value >= 0 ? colors.getProfitColor() : colors.getLossColor(),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// 计算月度数据
  Map<int, double> _calculateMonthlyData() {
    final Map<int, double> monthlyProfitLoss = {};

    for (final transaction in transactions) {
      final month = transaction.date.month;
      final profitLoss = transaction.profitLoss.toDouble();

      monthlyProfitLoss[month] = (monthlyProfitLoss[month] ?? 0) + profitLoss;
    }

    // 确保所有月份都有数据（即使是0）
    for (int i = 1; i <= 12; i++) {
      monthlyProfitLoss[i] ??= 0;
    }

    return Map.fromEntries(
      monthlyProfitLoss.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
  }

  /// 计算Y轴最小值
  double _calculateMinY(Iterable<double> values) {
    if (values.isEmpty) return -1000;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    if (range == 0) {
      return min - 1000; // 如果所有值相同，给一些空间
    }

    final padding = range * 0.1; // 10% 的边距
    return min - padding;
  }

  /// 计算Y轴最大值
  double _calculateMaxY(Iterable<double> values) {
    if (values.isEmpty) return 1000;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    if (range == 0) {
      return max + 1000; // 如果所有值相同，给一些空间
    }

    final padding = range * 0.1; // 10% 的边距
    return max + padding;
  }

  /// 计算合适的间隔
  double _calculateInterval(Iterable<double> values) {
    if (values.isEmpty) return 1000;

    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = max - min;

    if (range <= 1000) return 200;
    if (range <= 5000) return 1000;
    if (range <= 10000) return 2000;
    if (range <= 50000) return 10000;
    return 20000;
  }

  /// 格式化货币
  String _formatCurrency(double value) {
    if (value.abs() >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
