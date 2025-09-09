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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final titleFontSize = isMobile ? 16.0 : null;
        final pieRadius = isMobile ? 60.0 : 80.0;
        final centerSpaceRadius = isMobile ? 30.0 : 40.0;
        final titleStyleFontSize = isMobile ? 10.0 : 12.0;
        final legendFontSize = isMobile ? 11.0 : 12.0;
        final legendSpacing = isMobile ? 6.0 : 8.0;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Expanded(
                  child: isMobile ? _buildMobileLayout(
                    chartData, 
                    theme, 
                    pieRadius, 
                    centerSpaceRadius, 
                    titleStyleFontSize, 
                    legendFontSize, 
                    legendSpacing
                  ) : _buildDesktopLayout(
                    chartData, 
                    theme, 
                    pieRadius, 
                    centerSpaceRadius, 
                    titleStyleFontSize, 
                    legendFontSize, 
                    legendSpacing
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    List<ChartData> chartData,
    ThemeData theme,
    double pieRadius,
    double centerSpaceRadius,
    double titleStyleFontSize,
    double legendFontSize,
    double legendSpacing,
  ) {
    return Column(
      children: [
        // 饼图在上方
        Expanded(
          flex: 2,
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
                  radius: pieRadius,
                  titleStyle: TextStyle(
                    fontSize: titleStyleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: centerSpaceRadius,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 图例在下方，使用网格布局
        Expanded(
          flex: 1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 4,
            ),
            itemCount: chartData.length,
            itemBuilder: (context, index) {
              final data = chartData[index];
              final color = _getColor(index);
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          '¥${_formatValue(data.value)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    List<ChartData> chartData,
    ThemeData theme,
    double pieRadius,
    double centerSpaceRadius,
    double titleStyleFontSize,
    double legendFontSize,
    double legendSpacing,
  ) {
    return Row(
      children: [
        // 饼图
        Expanded(
          flex: 2,
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
                  radius: pieRadius,
                  titleStyle: TextStyle(
                    fontSize: titleStyleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: centerSpaceRadius,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // 图例
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final color = _getColor(index);
                
                return Padding(
                  padding: EdgeInsets.only(bottom: legendSpacing),
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
                                fontSize: legendFontSize,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '¥${data.value.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: legendFontSize - 1,
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
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  List<ChartData> _prepareChartData() {
    if (transactions.isEmpty) return [];

    // 按股票分组计算净持仓金额（买入-卖出）
    final stockData = <String, double>{};
    
    for (final transaction in transactions) {
      final key = transaction.stockName; // 只使用股票名称作为key
      // 计算净投资金额：正数表示买入，负数表示卖出
      final netAmount = transaction.amount.toDouble() * transaction.unitPrice.toDouble();
      stockData[key] = (stockData[key] ?? 0) + netAmount;
    }

    // 过滤掉净值为0或负数的股票（已卖完或卖空）
    stockData.removeWhere((key, value) => value <= 0);

    // 计算总金额（只计算正值）
    final totalAmount = stockData.values.fold(0.0, (sum, value) => sum + value);
    
    if (totalAmount <= 0) return [];

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
