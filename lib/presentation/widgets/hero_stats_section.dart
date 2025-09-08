import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/services/transaction_stats_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/color_theme_provider.dart';

/// Hero统计概览区域 - 显示关键投资指标
class HeroStatsSection extends ConsumerWidget {
  final VoidCallback? onTap;
  
  const HeroStatsSection({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final comprehensiveStatsAsync = ref.watch(comprehensiveStatsProvider);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return comprehensiveStatsAsync.when(
      data: (stats) => colorsAsync.when(
        data: (colors) => _buildStatsCard(context, stats, colors),
        loading: () => _buildLoadingCard(context),
        error: (_, __) => _buildErrorCard(context),
      ),
      loading: () => _buildLoadingCard(context),
      error: (error, _) => _buildErrorCard(context, error: error.toString()),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, 
    ComprehensiveStats stats, 
    dynamic colors,
  ) {
    final theme = Theme.of(context);
    final netProfitColor = colors.getColorByValue(stats.netProfit);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.trendingUp,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '投资概览',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  if (onTap != null)
                    Icon(
                      LucideIcons.chevronRight,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Stats
              Row(
                children: [
                  Expanded(
                    child: _MainStatCard(
                      label: '净盈亏',
                      value: stats.netProfit,
                      color: netProfitColor,
                      icon: stats.netProfit >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      isMain: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MainStatCard(
                      label: '今日盈亏',
                      value: stats.todayProfit,
                      color: colors.getColorByValue(stats.todayProfit),
                      icon: LucideIcons.calendar,
                      isMain: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Secondary Stats
              Row(
                children: [
                  Expanded(
                    child: _SecondaryStatItem(
                      label: '胜率',
                      value: '${stats.winRate.toStringAsFixed(1)}%',
                      icon: LucideIcons.target,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  Expanded(
                    child: _SecondaryStatItem(
                      label: 'ROI',
                      value: '${stats.roi.toStringAsFixed(2)}%',
                      icon: LucideIcons.percent,
                      color: colors.getColorByValue(stats.roi),
                    ),
                  ),
                  Expanded(
                    child: _SecondaryStatItem(
                      label: '股票数',
                      value: '${stats.uniqueStocks}',
                      icon: LucideIcons.pieChart,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  Expanded(
                    child: _SecondaryStatItem(
                      label: '交易笔数',
                      value: '${stats.totalTransactions}',
                      icon: LucideIcons.receipt,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: theme.colorScheme.onErrorContainer,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '统计数据加载失败',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 主要统计卡片
class _MainStatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isMain;

  const _MainStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(value),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isMain ? 24 : 20,
            ),
          ),
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
      return '$sign${(absValue / 1000).toStringAsFixed(2)}k';
    } else {
      return '$sign${absValue.toStringAsFixed(2)}';
    }
  }
}

/// 次要统计项目
class _SecondaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SecondaryStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}