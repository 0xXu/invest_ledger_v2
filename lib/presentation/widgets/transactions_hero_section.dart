import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/services/transaction_stats_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/color_theme_provider.dart';

/// 交易记录专属的英雄统计区域
class TransactionsHeroSection extends ConsumerWidget {
  final VoidCallback? onAnalyticsTap;
  
  const TransactionsHeroSection({
    super.key,
    this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final comprehensiveStatsAsync = ref.watch(comprehensiveStatsProvider);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return comprehensiveStatsAsync.when(
      data: (stats) => colorsAsync.when(
        data: (colors) => _buildHeroCard(context, stats, colors),
        loading: () => _buildLoadingCard(context),
        error: (_, __) => _buildErrorCard(context),
      ),
      loading: () => _buildLoadingCard(context),
      error: (error, _) => _buildErrorCard(context, error: error.toString()),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, 
    ComprehensiveStats stats, 
    dynamic colors,
  ) {
    final theme = Theme.of(context);
    final todayProfitColor = colors.getColorByValue(stats.todayProfit);
    final netProfitColor = colors.getColorByValue(stats.netProfit);
    
    return GestureDetector(
      onTap: onAnalyticsTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              todayProfitColor.withValues(alpha: 0.08),
              todayProfitColor.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: todayProfitColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: todayProfitColor.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部区域：图标 + 总览信息
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: todayProfitColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      stats.todayProfit >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: todayProfitColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日表现',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(stats.todayProfit),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: todayProfitColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (stats.todayTransactions > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${stats.todayTransactions}笔交易',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 核心指标网格
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: '总净收益',
                      value: _formatCurrency(stats.netProfit),
                      color: netProfitColor,
                      icon: stats.netProfit >= 0 ? LucideIcons.plus : LucideIcons.minus,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: '胜率',
                      value: '${stats.winRate.toStringAsFixed(1)}%',
                      color: stats.winRate >= 50 ? colors.getProfitColor() : colors.getLossColor(),
                      icon: LucideIcons.target,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: '总交易笔数',
                      value: stats.totalTransactions.toString(),
                      color: theme.colorScheme.primary,
                      icon: LucideIcons.fileBarChart,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: '活跃股票',
                      value: stats.uniqueStocks.toString(),
                      color: theme.colorScheme.secondary,
                      icon: LucideIcons.building2,
                    ),
                  ),
                ],
              ),
              
              // 分析页面入口提示
              if (onAnalyticsTap != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.barChart3,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '点击查看详细分析',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, {String? error}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: theme.colorScheme.onErrorContainer,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '数据加载失败',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final absValue = value.abs();
    final sign = value >= 0 ? '+' : '-';
    
    if (absValue >= 10000) {
      return '$sign${(absValue / 10000).toStringAsFixed(2)}万';
    } else if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(1)}k';
    } else {
      return '$sign${absValue.toStringAsFixed(2)}';
    }
  }
}