import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/ai_analysis_result.dart';

class TechnicalAnalysisWidget extends StatefulWidget {
  final TechnicalAnalysisData data;
  final AgentDetailedAnalysis agentAnalysis;

  const TechnicalAnalysisWidget({
    super.key,
    required this.data,
    required this.agentAnalysis,
  });

  @override
  State<TechnicalAnalysisWidget> createState() => _TechnicalAnalysisWidgetState();
}

class _TechnicalAnalysisWidgetState extends State<TechnicalAnalysisWidget> {
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

            // Strategy Signals
            if (widget.data.strategySignals?.isNotEmpty == true) ...[
              _buildStrategySignals(),
              const SizedBox(height: 16),
            ],

            // Technical Indicators
            if (widget.data.indicators?.isNotEmpty == true) ...[
              _buildTechnicalIndicators(),
              const SizedBox(height: 16),
            ],

            // Patterns
            if (widget.data.patterns?.isNotEmpty == true) ...[
              _buildPatterns(),
              const SizedBox(height: 16),
            ],

            // Execution Details
            _buildExecutionDetails(),
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
            LucideIcons.trendingUp,
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
                '技术分析',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '基于价格走势、指标和技术模式的分析',
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
                  '总体信号',
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

  Widget _buildStrategySignals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.layers, size: 20),
            const SizedBox(width: 8),
            Text(
              '策略信号',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.data.strategySignals!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildStrategySignalCard(entry.key, entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildStrategySignalCard(String strategyName, StrategySignal signal) {
    final signalColor = _getSignalColor(signal.signal);
    final signalIcon = _getSignalIcon(signal.signal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(signalIcon, color: signalColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStrategyDisplayName(strategyName),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (signal.metrics?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatMetrics(signal.metrics!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                signal.signal.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: signalColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                signal.confidence,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalIndicators() {
    if (!_showDetails) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.barChart3, size: 20),
            const SizedBox(width: 8),
            Text(
              '技术指标',
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
            children: widget.data.indicators!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getIndicatorDisplayName(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _formatIndicatorValue(entry.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
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

  Widget _buildPatterns() {
    if (!_showDetails) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.activity, size: 20),
            const SizedBox(width: 8),
            Text(
              '技术形态',
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
            children: widget.data.patterns!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getPatternDisplayName(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _formatPatternValue(entry.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
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
    if (!_showDetails) return const SizedBox.shrink();

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

  String _getStrategyDisplayName(String strategy) {
    const strategyMap = {
      'trend_following': '趋势跟踪',
      'mean_reversion': '均值回归',
      'momentum': '动量策略',
      'volatility': '波动率分析',
      'statistical_arbitrage': '统计套利',
    };
    return strategyMap[strategy] ?? strategy;
  }

  String _getIndicatorDisplayName(String indicator) {
    const indicatorMap = {
      'macd': 'MACD',
      'rsi': 'RSI',
      'bollinger_bands': '布林带',
      'moving_average': '移动平均线',
      'volume': '成交量',
      'atr': 'ATR',
    };
    return indicatorMap[indicator] ?? indicator;
  }

  String _getPatternDisplayName(String pattern) {
    const patternMap = {
      'support_resistance': '支撑阻力',
      'trend_lines': '趋势线',
      'chart_patterns': '图表形态',
      'candlestick_patterns': 'K线形态',
    };
    return patternMap[pattern] ?? pattern;
  }

  String _formatMetrics(Map<String, dynamic> metrics) {
    final entries = metrics.entries.take(2);
    return entries.map((e) => '${e.key}: ${_formatValue(e.value)}').join(', ');
  }

  String _formatIndicatorValue(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatPatternValue(dynamic value) {
    if (value is bool) {
      return value ? '检测到' : '未检测到';
    }
    return value.toString();
  }

  String _formatValue(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
