import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../providers/ai_suggestion_provider.dart';

class SuggestionDetailPage extends ConsumerWidget {
  final String suggestionId;

  const SuggestionDetailPage({
    super.key,
    required this.suggestionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(suggestionDetailProvider(suggestionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('建议详情'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share),
            tooltip: '分享',
            onPressed: () {
              // TODO: 实现分享功能
            },
          ),
        ],
      ),
      body: suggestionAsync.when(
        data: (suggestion) {
          if (suggestion == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.fileX,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '建议不存在',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 建议概览卡片
                _buildSuggestionOverview(context, suggestion),
                const SizedBox(height: 16),

                // 分析结果卡片
                _buildAnalysisResult(context, suggestion),
                const SizedBox(height: 16),

                // 操作按钮
                if (suggestion.status == AISuggestionStatus.pending)
                  _buildActionButtons(context, ref, suggestion),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionOverview(BuildContext context, AISuggestion suggestion) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.lightbulb, size: 20),
                const SizedBox(width: 8),
                Text(
                  '投资建议',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基本信息
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '股票',
                    '${suggestion.analysis.stockName} (${suggestion.analysis.stockCode})',
                    LucideIcons.building,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '状态',
                    _getStatusText(suggestion.status),
                    LucideIcons.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '创建时间',
                    _formatDateTime(suggestion.createdAt),
                    LucideIcons.clock,
                  ),
                ),
                if (suggestion.executedAt != null)
                  Expanded(
                    child: _buildInfoItem(
                      '执行时间',
                      _formatDateTime(suggestion.executedAt!),
                      LucideIcons.checkCircle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(BuildContext context, AISuggestion suggestion) {
    final theme = Theme.of(context);
    final analysis = suggestion.analysis;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart3, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI分析结果',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 投资决策
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getActionColor(analysis.action).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getActionColor(analysis.action).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(
                        _getActionIcon(analysis.action),
                        color: _getActionColor(analysis.action),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '建议操作',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        analysis.action.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getActionColor(analysis.action),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Icon(
                        LucideIcons.target,
                        color: _getConfidenceColor(analysis.confidence),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '置信度',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(analysis.confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getConfidenceColor(analysis.confidence),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Icon(
                        LucideIcons.hash,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '建议数量',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${analysis.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (analysis.reasoning.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '分析推理',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysis.reasoning,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, AISuggestion suggestion) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: 实现执行建议功能
            },
            icon: const Icon(LucideIcons.play),
            label: const Text('执行建议'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: 实现忽略建议功能
            },
            icon: const Icon(LucideIcons.x),
            label: const Text('忽略建议'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return LucideIcons.trendingUp;
      case 'sell':
        return LucideIcons.trendingDown;
      default:
        return LucideIcons.minus;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(AISuggestionStatus status) {
    switch (status) {
      case AISuggestionStatus.pending:
        return '待处理';
      case AISuggestionStatus.executed:
        return '已执行';
      case AISuggestionStatus.ignored:
        return '已忽略';
      case AISuggestionStatus.expired:
        return '已过期';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
