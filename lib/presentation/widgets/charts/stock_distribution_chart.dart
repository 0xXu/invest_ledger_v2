import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/models/transaction.dart';

class StockDistributionChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String title;

  const StockDistributionChart({
    super.key,
    required this.transactions,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
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
                Icons.pie_chart,
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
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // 饼图
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: chartData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final color = _getColor(index);
                          
                          return PieChartSectionData(
                            color: color,
                            value: data.value,
                            title: '${data.percentage.toStringAsFixed(1)}%',
                            radius: 80,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch events if needed
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 图例
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chartData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final color = _getColor(index);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '¥${data.value.toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ChartData> _prepareChartData() {
    if (transactions.isEmpty) return [];

    // 按股票分组计算总投资金额
    final stockData = <String, double>{};
    
    for (final transaction in transactions) {
      final key = '${transaction.stockName}\n(${transaction.stockCode})';
      final investmentAmount = (transaction.amount * transaction.unitPrice).toDouble();
      stockData[key] = (stockData[key] ?? 0) + investmentAmount;
    }

    // 计算总金额
    final totalAmount = stockData.values.fold(0.0, (sum, value) => sum + value);
    
    if (totalAmount == 0) return [];

    // 转换为图表数据并按金额排序
    final sortedEntries = stockData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 只显示前6个，其余合并为"其他"
    final result = <ChartData>[];
    const maxItems = 6;
    
    if (sortedEntries.length <= maxItems) {
      for (final entry in sortedEntries) {
        final percentage = (entry.value / totalAmount) * 100;
        result.add(ChartData(
          label: entry.key,
          value: entry.value,
          percentage: percentage,
        ));
      }
    } else {
      // 添加前5个
      for (int i = 0; i < maxItems - 1; i++) {
        final entry = sortedEntries[i];
        final percentage = (entry.value / totalAmount) * 100;
        result.add(ChartData(
          label: entry.key,
          value: entry.value,
          percentage: percentage,
        ));
      }
      
      // 合并剩余的为"其他"
      final othersValue = sortedEntries
          .skip(maxItems - 1)
          .fold(0.0, (sum, entry) => sum + entry.value);
      final othersPercentage = (othersValue / totalAmount) * 100;
      
      result.add(ChartData(
        label: '其他',
        value: othersValue,
        percentage: othersPercentage,
      ));
    }

    return result;
  }

  Color _getColor(int index) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
    ];
    return colors[index % colors.length];
  }
}

class ChartData {
  final String label;
  final double value;
  final double percentage;

  ChartData({
    required this.label,
    required this.value,
    required this.percentage,
  });
}
