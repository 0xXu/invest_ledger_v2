import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/ai_analysis_result.dart';

class FundamentalAnalysisWidget extends StatefulWidget {
  final FundamentalAnalysisData data;
  final AgentDetailedAnalysis agentAnalysis;

  const FundamentalAnalysisWidget({
    super.key,
    required this.data,
    required this.agentAnalysis,
  });

  @override
  State<FundamentalAnalysisWidget> createState() => _FundamentalAnalysisWidgetState();
}

class _FundamentalAnalysisWidgetState extends State<FundamentalAnalysisWidget> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),

            // Overall Signal
            _buildOverallSignal(),
            const SizedBox(height: 16),

            // Financial Metrics
            if (widget.data.metrics?.isNotEmpty == true) ...[
              _buildFinancialMetrics(),
              const SizedBox(height: 16),
            ],

            // Financial Ratios
            if (widget.data.ratios?.isNotEmpty == true) ...[
              _buildFinancialRatios(),
              const SizedBox(height: 16),
            ],

            // Reasoning Details
            if (widget.data.reasoning?.isNotEmpty == true && _showDetails) ...[
              _buildReasoningDetails(),
              const SizedBox(height: 16),
            ],

            // Execution Details
            if (_showDetails) _buildExecutionDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            LucideIcons.pieChart,
            color: Colors.blue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '基本面分析',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '基于财务指标、盈利能力和增长潜力的分析',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _showDetails = !_showDetails;
            });
          },
          icon: Icon(
            _showDetails ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallSignal() {
    final signalColor = _getSignalColor(widget.data.signal);
    final signalIcon = _getSignalIcon(widget.data.signal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: signalColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signalColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(signalIcon, color: signalColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '基本面评级',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.signal.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: signalColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '置信度',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.data.confidence,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: signalColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.dollarSign, size: 20),
            const SizedBox(width: 8),
            Text(
              '财务指标',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: widget.data.metrics!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildMetricRow(entry.key, entry.value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRatios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.calculator, size: 20),
            const SizedBox(width: 8),
            Text(
              '财务比率',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: widget.data.ratios!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildRatioRow(entry.key, entry.value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String key, dynamic value) {
    final displayName = _getMetricDisplayName(key);
    final formattedValue = _formatMetricValue(key, value);
    final color = _getMetricColor(key, value);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Text(
            formattedValue,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioRow(String key, dynamic value) {
    final displayName = _getRatioDisplayName(key);
    final formattedValue = _formatRatioValue(key, value);
    final color = _getRatioColor(key, value);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Text(
            formattedValue,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasoningDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.fileText, size: 20),
            const SizedBox(width: 8),
            Text(
              '分析详情',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: widget.data.reasoning!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        _getReasoningDisplayName(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatReasoningValue(entry.value),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.clock, size: 20),
            const SizedBox(width: 8),
            Text(
              '执行详情',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('开始时间', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    _formatDateTime(widget.agentAnalysis.startTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('执行时长', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${widget.agentAnalysis.executionTimeSeconds.toStringAsFixed(1)}秒',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('状态', style: Theme.of(context).textTheme.bodyMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.agentAnalysis.status.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getSignalColor(String signal) {
    switch (signal.toLowerCase()) {
      case 'bullish':
        return Colors.green;
      case 'bearish':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSignalIcon(String signal) {
    switch (signal.toLowerCase()) {
      case 'bullish':
        return LucideIcons.trendingUp;
      case 'bearish':
        return LucideIcons.trendingDown;
      default:
        return LucideIcons.minus;
    }
  }

  String _getMetricDisplayName(String metric) {
    const metricMap = {
      'return_on_equity': 'ROE (净资产收益率)',
      'net_margin': '净利润率',
      'operating_margin': '营业利润率',
      'revenue_growth': '营收增长率',
      'earnings_growth': '净利润增长率',
      'current_ratio': '流动比率',
      'debt_to_equity': '资产负债率',
      'free_cash_flow': '自由现金流',
      'earnings_per_share': '每股收益',
    };
    return metricMap[metric] ?? metric;
  }

  String _getRatioDisplayName(String ratio) {
    const ratioMap = {
      'pe_ratio': '市盈率 (P/E)',
      'price_to_book': '市净率 (P/B)',
      'price_to_sales': '市销率 (P/S)',
      'dividend_yield': '股息收益率',
      'peg_ratio': 'PEG比率',
    };
    return ratioMap[ratio] ?? ratio;
  }

  String _getReasoningDisplayName(String key) {
    const reasoningMap = {
      'profitability': '盈利能力',
      'growth': '成长性',
      'financial_health': '财务健康',
      'efficiency': '运营效率',
      'valuation': '估值水平',
    };
    return reasoningMap[key] ?? key;
  }

  String _formatMetricValue(String key, dynamic value) {
    if (value is num) {
      if (key.contains('ratio') || key.contains('margin') || key.contains('growth')) {
        return '${(value * 100).toStringAsFixed(1)}%';
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatRatioValue(String key, dynamic value) {
    if (value is num) {
      if (key.contains('yield')) {
        return '${(value * 100).toStringAsFixed(2)}%';
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatReasoningValue(dynamic value) {
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  Color? _getMetricColor(String key, dynamic value) {
    if (value is! num) return null;

    switch (key) {
      case 'return_on_equity':
        return value > 0.15 ? Colors.green : value > 0.1 ? Colors.orange : Colors.red;
      case 'net_margin':
        return value > 0.2 ? Colors.green : value > 0.1 ? Colors.orange : Colors.red;
      case 'revenue_growth':
      case 'earnings_growth':
        return value > 0.1 ? Colors.green : value > 0 ? Colors.orange : Colors.red;
      default:
        return null;
    }
  }

  Color? _getRatioColor(String key, dynamic value) {
    if (value is! num) return null;

    switch (key) {
      case 'pe_ratio':
        return value < 15 ? Colors.green : value < 25 ? Colors.orange : Colors.red;
      case 'price_to_book':
        return value < 1.5 ? Colors.green : value < 3 ? Colors.orange : Colors.red;
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
