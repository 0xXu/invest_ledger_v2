import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/models/transaction.dart';
import '../../data/services/transaction_stats_service.dart';
import '../../core/utils/number_formatter.dart';
import '../providers/transaction_provider.dart';
import '../providers/color_theme_provider.dart';

/// Hero统计概览区域 - 显示关键投资指标
class HeroStatsSection extends ConsumerWidget {
  final VoidCallback? onTap;
  final List<Transaction>? filteredTransactions; // 筛选后的交易列表
  
  const HeroStatsSection({
    super.key,
    this.onTap,
    this.filteredTransactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    // 如果有筛选后的数据，直接计算统计；否则使用全部数据
    if (filteredTransactions != null) {
      final service = TransactionStatsService();
      final stats = service.calculateComprehensiveStats(filteredTransactions!);
      
      return colorsAsync.when(
        data: (colors) => _buildStatsCard(context, stats, colors, isFiltered: true),
        loading: () => _buildLoadingCard(context),
        error: (_, __) => _buildErrorCard(context),
      );
    } else {
      // 使用原有的provider获取全部数据
      final comprehensiveStatsAsync = ref.watch(comprehensiveStatsProvider);
      
      return comprehensiveStatsAsync.when(
        data: (stats) => colorsAsync.when(
          data: (colors) => _buildStatsCard(context, stats, colors, isFiltered: false),
          loading: () => _buildLoadingCard(context),
          error: (_, __) => _buildErrorCard(context),
        ),
        loading: () => _buildLoadingCard(context),
        error: (error, _) => _buildErrorCard(context, error: error.toString()),
      );
    }
  }

  Widget _buildStatsCard(
    BuildContext context, 
    ComprehensiveStats stats, 
    dynamic colors,
    {required bool isFiltered}
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
              isFiltered 
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.primaryContainer,
              (isFiltered 
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.primaryContainer).withValues(alpha: 0.7),
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
                          color: isFiltered 
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isFiltered ? LucideIcons.filter : LucideIcons.trendingUp,
                          color: isFiltered 
                            ? theme.colorScheme.onSecondary
                            : theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFiltered ? '筛选结果' : '投资概览',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isFiltered 
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (isFiltered) ...[
                            const SizedBox(height: 2),
                            Text(
                              '基于当前筛选条件',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: (isFiltered 
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onPrimaryContainer).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (onTap != null)
                    Icon(
                      LucideIcons.chevronRight,
                      color: (isFiltered 
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onPrimaryContainer).withValues(alpha: 0.7),
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
                      label: isFiltered ? '总盈利' : '今日盈亏',
                      value: isFiltered ? stats.totalProfit : stats.todayProfit,
                      color: isFiltered 
                        ? colors.getColorByValue(stats.totalProfit)
                        : colors.getColorByValue(stats.todayProfit),
                      icon: isFiltered ? LucideIcons.plus : LucideIcons.calendar,
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
                      label: isFiltered ? '总亏损' : '胜率',
                      value: isFiltered 
                        ? NumberFormatter.formatCurrency(stats.totalLoss, showSign: true)
                        : NumberFormatter.formatPercentage(stats.winRate),
                      icon: isFiltered ? LucideIcons.minus : LucideIcons.target,
                      color: isFiltered ? Colors.red : theme.colorScheme.secondary,
                    ),
                  ),
                  Expanded(
                    child: _SecondaryStatItem(
                      label: isFiltered ? '胜率' : 'ROI',
                      value: isFiltered 
                        ? NumberFormatter.formatPercentage(stats.winRate)
                        : NumberFormatter.formatPercentage(stats.roi, decimalPlaces: 2),
                      icon: isFiltered ? LucideIcons.target : LucideIcons.percent,
                      color: isFiltered ? theme.colorScheme.secondary : colors.getColorByValue(stats.roi),
                    ),
                  ),
                  Expanded(
                    child: _SecondaryStatItem(
                      label: '股票数',
                      value: NumberFormatter.formatInteger(stats.uniqueStocks),
                      icon: LucideIcons.pieChart,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  Expanded(
                    child: _SecondaryStatItem(
                      label: '交易笔数',
                      value: NumberFormatter.formatInteger(stats.totalTransactions),
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
            NumberFormatter.formatCurrency(value),
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