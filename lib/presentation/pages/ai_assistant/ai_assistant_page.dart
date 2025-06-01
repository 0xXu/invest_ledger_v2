import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../providers/ai_suggestion_provider.dart';
import '../../widgets/refresh_button.dart';

class AIAssistantPage extends ConsumerWidget {
  const AIAssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiServiceStatusAsync = ref.watch(aiServiceStatusProvider);
    final pendingSuggestionsAsync = ref.watch(pendingAISuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI投资助手'),
        actions: [
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(aiServiceStatusProvider);
              ref.invalidate(pendingAISuggestionsProvider);
            },
            loadingMessage: '正在刷新...',
            tooltip: '刷新',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI服务状态卡片
            _buildServiceStatusCard(context, theme, aiServiceStatusAsync),
            const SizedBox(height: 16),

            // 功能入口卡片
            _buildFunctionCards(context, theme),
            const SizedBox(height: 16),

            // 待处理建议
            _buildPendingSuggestions(context, theme, pendingSuggestionsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard(BuildContext context, ThemeData theme, AsyncValue<bool> statusAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.activity, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI服务状态',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            statusAsync.when(
              data: (isAvailable) => Row(
                children: [
                  Icon(
                    isAvailable ? LucideIcons.checkCircle : LucideIcons.xCircle,
                    color: isAvailable ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? '服务正常运行' : '服务不可用',
                    style: TextStyle(
                      color: isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isAvailable) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        context.push('/ai-assistant/config');
                      },
                      icon: const Icon(LucideIcons.settings, size: 16),
                      label: const Text('配置'),
                    ),
                  ],
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('检查中...'),
                ],
              ),
              error: (error, stack) => Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '检查失败: $error',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionCards(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI功能',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildFunctionCard(
              context,
              title: 'AI股票分析',
              subtitle: '智能分析股票投资机会',
              icon: LucideIcons.trendingUp,
              color: Colors.blue,
              onTap: () {
                context.push('/ai-assistant/analysis');
              },
            ),
            _buildFunctionCard(
              context,
              title: 'AI回测分析',
              subtitle: '回测投资策略表现',
              icon: LucideIcons.barChart3,
              color: Colors.red,
              onTap: () {
                context.push('/ai-assistant/backtest');
              },
            ),
            _buildFunctionCard(
              context,
              title: 'AI建议管理',
              subtitle: '查看和管理AI投资建议',
              icon: LucideIcons.lightbulb,
              color: Colors.orange,
              onTap: () {
                context.push('/ai-assistant/suggestions');
              },
            ),
            _buildFunctionCard(
              context,
              title: '分析历史',
              subtitle: '查看历史分析记录',
              icon: LucideIcons.history,
              color: Colors.green,
              onTap: () {
                context.push('/ai-assistant/history');
              },
            ),
            _buildFunctionCard(
              context,
              title: 'AI配置',
              subtitle: '配置AI服务参数',
              icon: LucideIcons.settings,
              color: Colors.purple,
              onTap: () {
                context.push('/ai-assistant/config');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunctionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingSuggestions(BuildContext context, ThemeData theme, AsyncValue<List<AISuggestion>> suggestionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '待处理建议',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/ai-assistant/suggestions');
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        suggestionsAsync.when(
          data: (suggestions) {
            if (suggestions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无待处理建议',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: suggestions.take(3).map((suggestion) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      LucideIcons.lightbulb,
                      color: Colors.orange,
                    ),
                    title: Text('${suggestion.analysis.stockName} (${suggestion.analysis.stockCode})'),
                    subtitle: Text(
                      '${suggestion.analysis.action.toUpperCase()} - ${(suggestion.analysis.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      context.push('/ai-assistant/suggestion/${suggestion.id}');
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '加载失败: $error',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
