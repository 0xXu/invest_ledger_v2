import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/models/transaction.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../providers/color_theme_provider.dart';

class ProfitLossChart extends ConsumerWidget {
  final List<Transaction> transactions;
  final String title;

  const ProfitLossChart({
    super.key,
    required this.transactions,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => _buildChart(context, colors),
      loading: () => Card(
        child: SizedBox(
          height: 380,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: SizedBox(
          height: 380,
          child: const Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, ProfitLossColors colors) {
    final theme = Theme.of(context);
    final chartData = _prepareChartData();

    if (chartData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.bar_chart,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无数据',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[ 
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  minY: _getMinY(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = chartData[groupIndex];
                        return BarTooltipItem(
                          '${data.label}\n¥${data.value.toStringAsFixed(2)}',
                          TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
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
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[index].label,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '¥${_formatNumber(value)}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: chartData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.value,
                          color: data.value >= 0
                              ? colors.getProfitColor()
                              : colors.getLossColor(),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChartData> _prepareChartData() {
    if (transactions.isEmpty) return [];

    // 按月份分组
    final monthlyData = <String, double>{};

    for (final transaction in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + transaction.profitLoss.toDouble();
    }

    // 转换为图表数据
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.map((entry) {
      final date = DateTime.parse('${entry.key}-01');
      final label = DateFormat('MM月').format(date);
      return ChartData(label: label, value: entry.value);
    }).toList();
  }

  double _getMaxY() {
    final values = chartData.map((e) => e.value).toList();
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.2 : 100;
  }

  double _getMinY() {
    final values = chartData.map((e) => e.value).toList();
    if (values.isEmpty) return -100;
    final min = values.reduce((a, b) => a < b ? a : b);
    return min < 0 ? min * 1.2 : -100;
  }

  String _formatNumber(double value) {
    if (value.abs() >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  List<ChartData> get chartData => _prepareChartData();
}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}
