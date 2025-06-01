import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../../data/services/ai_service.dart';
import '../../widgets/refresh_button.dart';

class BacktestPage extends ConsumerStatefulWidget {
  const BacktestPage({super.key});

  @override
  ConsumerState<BacktestPage> createState() => _BacktestPageState();
}

class _BacktestPageState extends ConsumerState<BacktestPage> {
  final _formKey = GlobalKey<FormState>();
  final _stockCodeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _initialCapitalController = TextEditingController(text: '100000');
  final _numOfNewsController = TextEditingController(text: '5');

  BacktestResult? _backtestResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 设置默认日期范围（最近30天）
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    _startDateController.text = _formatDate(startDate);
    _endDateController.text = _formatDate(now);
  }

  @override
  void dispose() {
    _stockCodeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _initialCapitalController.dispose();
    _numOfNewsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  Future<void> _startBacktest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _backtestResult = null;
    });

    try {
      print('🚀 开始回测请求');
      print('📊 参数: 股票=${_stockCodeController.text.trim()}, 开始=${_startDateController.text}, 结束=${_endDateController.text}');
      print('💰 资金=${_initialCapitalController.text}, 新闻=${_numOfNewsController.text}');

      final aiService = AIService();
      print('🔧 AI服务已创建');

      final result = await aiService.startBacktest(
        stockCode: _stockCodeController.text.trim(),
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        initialCapital: double.parse(_initialCapitalController.text),
        numOfNews: int.parse(_numOfNewsController.text),
      );

      print('✅ 回测完成，结果: ${result.toString()}');

      if (mounted) {
        setState(() {
          _backtestResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI回测分析'),
        actions: [
          RefreshButton.icon(
            onRefresh: () async {
              setState(() {
                _backtestResult = null;
                _errorMessage = null;
              });
            },
            loadingMessage: '正在重置...',
            tooltip: '重置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 参数设置卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.settings,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '回测参数设置',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 股票代码
                      TextFormField(
                        controller: _stockCodeController,
                        decoration: const InputDecoration(
                          labelText: '股票代码',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入股票代码';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 日期范围
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateController,
                              decoration: const InputDecoration(
                                labelText: '开始日期',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(LucideIcons.calendar),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(_startDateController),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请选择开始日期';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDateController,
                              decoration: const InputDecoration(
                                labelText: '结束日期',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(LucideIcons.calendar),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(_endDateController),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请选择结束日期';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 初始资金和新闻数量
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _initialCapitalController,
                              decoration: const InputDecoration(
                                labelText: '初始资金',
                                border: OutlineInputBorder(),
                                suffixText: '元',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入初始资金';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return '请输入有效的金额';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _numOfNewsController,
                              decoration: const InputDecoration(
                                labelText: '新闻数量',
                                border: OutlineInputBorder(),
                                suffixText: '条',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入新闻数量';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 1 || num > 100) {
                                  return '请输入1-100之间的数字';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 开始回测按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _startBacktest,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.play),
                          label: Text(_isLoading ? '回测进行中...' : '开始回测'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 错误信息
            if (_errorMessage != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // 回测结果
            if (_backtestResult != null) ...[
              const SizedBox(height: 16),
              _buildBacktestResult(_backtestResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBacktestResult(BacktestResult result) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // 性能指标卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '回测性能指标',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 性能指标网格
                if (result.performanceMetrics.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: result.performanceMetrics.length,
                    itemBuilder: (context, index) {
                      final entry = result.performanceMetrics.entries.elementAt(index);
                      return _buildMetricCard(entry.key, entry.value);
                    },
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 图表卡片
        if (result.timeSeriesData.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.barChart3,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '回测结果图表',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 显示图表
                  _buildCharts(result.timeSeriesData),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard(String label, double value) {
    final theme = Theme.of(context);
    
    // 格式化标签
    String displayLabel = _formatMetricLabel(label);
    String displayValue = _formatMetricValue(label, value);
    Color valueColor = _getMetricColor(label, value);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(List<BacktestDataPoint> timeSeriesData) {
    if (timeSeriesData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.barChart3, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              '暂无图表数据',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 组合价值图表
        _buildPortfolioValueChart(timeSeriesData),
        const SizedBox(height: 24),
        // 累计收益率图表
        _buildCumulativeReturnChart(timeSeriesData),
      ],
    );
  }

  Widget _buildPortfolioValueChart(List<BacktestDataPoint> data) {
    final theme = Theme.of(context);

    // 准备数据点
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.portfolioValue / 1000); // 转换为千元
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '组合价值变化',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.2),
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
                    interval: (data.length / 5).ceilToDouble(),
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = DateTime.parse(data[index].date);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${date.month}/${date.day}',
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
                    interval: 10,
                    reservedSize: 60,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toStringAsFixed(1)}K',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCumulativeReturnChart(List<BacktestDataPoint> data) {
    final theme = Theme.of(context);

    // 准备数据点
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.cumulativeReturn);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '累计收益率变化',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.2),
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
                    interval: (data.length / 5).ceilToDouble(),
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = DateTime.parse(data[index].date);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${date.month}/${date.day}',
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
                    interval: 2,
                    reservedSize: 60,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.green,
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatMetricLabel(String label) {
    switch (label) {
      case 'total_return':
        return '总收益率';
      case 'sharpe_ratio':
        return '夏普比率';
      case 'max_drawdown':
        return '最大回撤';
      case 'final_value':
        return '最终价值';
      case 'total_trades':
        return '交易次数';
      default:
        return label;
    }
  }

  String _formatMetricValue(String label, double value) {
    switch (label) {
      case 'total_return':
      case 'max_drawdown':
        return '${(value * 100).toStringAsFixed(2)}%';
      case 'sharpe_ratio':
        return value.toStringAsFixed(3);
      case 'final_value':
        return '¥${value.toStringAsFixed(2)}';
      case 'total_trades':
        return value.toInt().toString();
      default:
        return value.toStringAsFixed(2);
    }
  }

  Color _getMetricColor(String label, double value) {
    switch (label) {
      case 'total_return':
        return value >= 0 ? Colors.green : Colors.red;
      case 'max_drawdown':
        return Colors.red;
      case 'sharpe_ratio':
        return value >= 1 ? Colors.green : (value >= 0 ? Colors.orange : Colors.red);
      default:
        return Colors.blue;
    }
  }
}
