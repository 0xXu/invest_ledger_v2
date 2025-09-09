import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/transaction.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../providers/color_theme_provider.dart';

class StockPerformanceChart extends ConsumerWidget {
  final List<Transaction> transactions;
  final String title;
  final double? height;
  final int maxStocks;

  const StockPerformanceChart({
    super.key,
    required this.transactions,
    required this.title,
    this.height,
    this.maxStocks = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final titleFontSize = isMobile ? 16.0 : null;
          final iconSize = isMobile ? 18.0 : 20.0;
          
          return Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.barChart3,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Expanded(
                    child: _buildChart(context, colors, isMobile),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => Card(
        child: SizedBox(
          height: 200,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: SizedBox(
          height: 200,
          child: const Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, ProfitLossColors colors, bool isMobile) {
    final stockData = _calculateStockPerformance();

    if (stockData.isEmpty) {
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

    final barGroups = stockData.asMap().entries.map((entry) {
      final index = entry.key;
      final stockInfo = entry.value;
      final profitLoss = stockInfo['profitLoss'] as double;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: profitLoss,
            color: profitLoss >= 0 ? colors.getProfitColor() : colors.getLossColor(),
            width: isMobile ? 15 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final labelFontSize = isMobile ? 8.0 : 10.0;
    final reservedSizeLeft = isMobile ? 50.0 : 60.0;
    final reservedSizeBottom = isMobile ? 35.0 : 40.0;
    final tooltipFontSize = isMobile ? 11.0 : 12.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: stockData.map((e) => e['profitLoss'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
        minY: stockData.map((e) => e['profitLoss'] as double).reduce((a, b) => a < b ? a : b) * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(stockData.map((e) => e['profitLoss'] as double)),
          getDrawingHorizontalLine: (value) {
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
              reservedSize: reservedSizeBottom,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stockData.length) return const Text('');

                final stockInfo = stockData[index];
                final stockName = stockInfo['stockName'] as String;
                // 在手机端截断过长的股票名称
                final displayName = isMobile && stockName.length > 4 
                    ? '${stockName.substring(0, 3)}...' 
                    : stockName;

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: EdgeInsets.only(top: isMobile ? 4 : 8),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: labelFontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(stockData.map((e) => e['profitLoss'] as double)),
              reservedSize: reservedSizeLeft,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatCurrency(value),
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: labelFontSize,
                    ),
                    textAlign: TextAlign.right,
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
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stockInfo = stockData[group.x];
              final stockCode = stockInfo['stockCode'] as String;
              final stockName = stockInfo['stockName'] as String;
              final profitLoss = stockInfo['profitLoss'] as double;
              final tradeCount = stockInfo['tradeCount'] as int;

              return BarTooltipItem(
                '$stockName\n'
                '盈亏: ${_formatCurrency(profitLoss)}\n'
                '交易次数: $tradeCount',
                TextStyle(
                  color: profitLoss >= 0 ? colors.getProfitColor() : colors.getLossColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: tooltipFontSize,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 计算股票表现数据
  List<Map<String, dynamic>> _calculateStockPerformance() {
    final Map<String, Map<String, dynamic>> stockStats = {};

    for (final transaction in transactions) {
      final key = '${transaction.stockCode}_${transaction.stockName}';

      if (!stockStats.containsKey(key)) {
        stockStats[key] = {
          'stockCode': transaction.stockCode,
          'stockName': transaction.stockName,
          'profitLoss': 0.0,
          'tradeCount': 0,
        };
      }

      stockStats[key]!['profitLoss'] =
          (stockStats[key]!['profitLoss'] as double) + transaction.profitLoss.toDouble();
      stockStats[key]!['tradeCount'] =
          (stockStats[key]!['tradeCount'] as int) + 1;
    }

    // 按盈亏排序，取前N个
    final sortedStocks = stockStats.values.toList()
      ..sort((a, b) => (b['profitLoss'] as double).compareTo(a['profitLoss'] as double));

    return sortedStocks.take(maxStocks).toList();
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
