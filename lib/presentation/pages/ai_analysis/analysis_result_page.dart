import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../providers/color_theme_provider.dart';
import 'detailed_analysis_page.dart';

class AnalysisResultPage extends ConsumerWidget {
  final AIAnalysisResult result;

  const AnalysisResultPage({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${result.stockName} (${result.stockCode})'),
        actions: [
          if (result.detailedAnalysis != null)
            IconButton(
              icon: const Icon(LucideIcons.fileText),
              tooltip: '详细分析',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailedAnalysisPage(result: result),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 投资决策卡片
            _buildDecisionCard(theme, colorsAsync),
            const SizedBox(height: 16),

            // Agent信号汇总
            _buildAgentSignalsCard(theme, colorsAsync),
            const SizedBox(height: 16),

            // 推理过程
            if (result.reasoning.isNotEmpty)
              _buildReasoningCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(ThemeData theme, AsyncValue<ProfitLossColors> colorsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getActionIcon(result.action),
                  size: 24,
                  color: _getActionColor(result.action),
                ),
                const SizedBox(width: 12),
                Text(
                  '投资决策',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 决策信息
            Row(
              children: [
                Expanded(
                  child: _buildDecisionItem(
                    '操作',
                    _getActionText(result.action),
                    _getActionColor(result.action),
                    LucideIcons.target,
                  ),
                ),
                Expanded(
                  child: _buildDecisionItem(
                    '数量',
                    '${result.quantity}股',
                    theme.colorScheme.primary,
                    LucideIcons.hash,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 置信度
            _buildConfidenceIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme) {
    final confidencePercent = (result.confidence * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '置信度',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$confidencePercent%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getConfidenceColor(result.confidence),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: result.confidence,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getConfidenceColor(result.confidence),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentSignalsCard(ThemeData theme, AsyncValue<ProfitLossColors> colorsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.users, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Agent分析结果',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...result.agentSignals.map((signal) =>
              _buildAgentSignalItem(signal, theme, colorsAsync)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentSignalItem(AgentSignal signal, ThemeData theme, AsyncValue<ProfitLossColors> colorsAsync) {
    return colorsAsync.when(
      data: (colors) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                signal.agent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSignalColor(signal.signal, colors).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSignalText(signal.signal),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getSignalColor(signal.signal, colors),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(signal.confidence * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getConfidenceColor(signal.confidence),
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildReasoningCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.brain, size: 20),
                const SizedBox(width: 8),
                Text(
                  '分析推理',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.reasoning,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return LucideIcons.trendingUp;
      case 'sell':
        return LucideIcons.trendingDown;
      case 'hold':
        return LucideIcons.pause;
      default:
        return LucideIcons.minus;
    }
  }

  String _getActionText(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return '买入';
      case 'sell':
        return '卖出';
      case 'hold':
        return '持有';
      default:
        return '持有';
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      case 'hold':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getSignalColor(String signal, ProfitLossColors colors) {
    switch (signal.toLowerCase()) {
      case 'bullish':
      case 'buy':
      case 'positive':
        return colors.getProfitColor();
      case 'bearish':
      case 'sell':
      case 'negative':
        return colors.getLossColor();
      case 'hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSignalText(String signal) {
    switch (signal.toLowerCase()) {
      case 'bullish':
      case 'buy':
        return '看涨';
      case 'bearish':
      case 'sell':
        return '看跌';
      case 'hold':
        return '持有';
      case 'positive':
        return '积极';
      case 'negative':
        return '消极';
      default:
        return '中性';
    }
  }
}
