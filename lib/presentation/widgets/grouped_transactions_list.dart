import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/models/transaction.dart';
import '../../data/services/transaction_stats_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/color_theme_provider.dart';
import 'profit_loss_record_card.dart';
import 'animated_card.dart';
import '../utils/loading_utils.dart';

/// 分组交易记录列表 - 按日期分组显示（盈亏记录模式）
class GroupedTransactionsList extends ConsumerStatefulWidget {
  final List<Transaction> transactions;
  final VoidCallback? onRefresh;

  const GroupedTransactionsList({
    super.key,
    required this.transactions,
    this.onRefresh,
  });

  @override
  ConsumerState<GroupedTransactionsList> createState() => _GroupedTransactionsListState();
}

class _GroupedTransactionsListState extends ConsumerState<GroupedTransactionsList> 
    with TickerProviderStateMixin {
  
  /// 存储每个日期组的展开状态
  final Map<DateTime, bool> _expandedStates = {};
  
  /// 动画控制器映射
  final Map<DateTime, AnimationController> _animationControllers = {};

  @override
  void dispose() {
    // 清理所有动画控制器
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 获取或创建动画控制器
  AnimationController _getAnimationController(DateTime date) {
    if (!_animationControllers.containsKey(date)) {
      _animationControllers[date] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      // 默认展开今日和昨日
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (date.isAtSameMomentAs(today) || date.isAtSameMomentAs(yesterday)) {
        _expandedStates[date] = true;
        _animationControllers[date]!.value = 1.0;
      } else {
        // 明确设置其他日期为收起状态
        _expandedStates[date] = false;
        _animationControllers[date]!.value = 0.0;
      }
    }
    return _animationControllers[date]!;
  }

  /// 切换展开状态
  void _toggleExpanded(DateTime date) {
    final controller = _getAnimationController(date);
    final isExpanded = _expandedStates[date] ?? false;
    
    setState(() {
      _expandedStates[date] = !isExpanded;
    });

    if (!isExpanded) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    final groupedTransactionsAsync = ref.watch(
      groupedTransactionsByDateProvider(widget.transactions)
    );

    return groupedTransactionsAsync.when(
      data: (groupedTransactions) => _buildGroupedList(groupedTransactions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildGroupedList(Map<DateTime, List<Transaction>> groupedTransactions) {
    final entries = groupedTransactions.entries.toList();
    
    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final date = entry.key;
          final dayTransactions = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DateGroupCard(
              date: date,
              transactions: dayTransactions,
              isExpanded: _expandedStates[date] ?? false,
              animationController: _getAnimationController(date),
              onToggleExpanded: () => _toggleExpanded(date),
              onTransactionTap: (transaction) {
                context.push('/transactions/${transaction.id}');
              },
              onTransactionEdit: (transaction) {
                context.push('/transactions/edit/${transaction.id}?mode=simple');
              },
              onTransactionDelete: (transaction) {
                _showDeleteDialog(context, transaction);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.trendingUp,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无盈亏记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的 + 按钮快速记录盈亏',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除盈亏记录'),
        content: Text(
          '确定要删除这条盈亏记录吗？此操作无法撤销。\n\n${transaction.stockName}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await ref.withLoading(() async {
                  await ref.read(transactionNotifierProvider.notifier)
                      .deleteTransaction(transaction.id!);
                }, '正在删除盈亏记录...');

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('盈亏记录已删除'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 日期分组卡片
class _DateGroupCard extends ConsumerWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final bool isExpanded;
  final AnimationController animationController;
  final VoidCallback onToggleExpanded;
  final Function(Transaction) onTransactionTap;
  final Function(Transaction) onTransactionEdit;
  final Function(Transaction) onTransactionDelete;

  const _DateGroupCard({
    required this.date,
    required this.transactions,
    required this.isExpanded,
    required this.animationController,
    required this.onToggleExpanded,
    required this.onTransactionTap,
    required this.onTransactionEdit,
    required this.onTransactionDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyStatsAsync = ref.watch(dailyStatsProvider(transactions));
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return dailyStatsAsync.when(
      data: (dailyStats) => colorsAsync.when(
        data: (colors) => Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 日期头部
              _buildDateHeader(context, dailyStats, colors),
              // 交易列表（可展开）
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: animationController.value,
                      child: child,
                    ),
                  );
                },
                child: _buildTransactionsList(context),
              ),
            ],
          ),
        ),
        loading: () => _buildLoadingCard(context),
        error: (_, __) => _buildErrorCard(context),
      ),
      loading: () => _buildLoadingCard(context),
      error: (_, __) => _buildErrorCard(context),
    );
  }

  Widget _buildDateHeader(BuildContext context, DailyStats dailyStats, dynamic colors) {
    final theme = Theme.of(context);
    final netProfitColor = colors.getColorByValue(dailyStats.netProfit);
    final isToday = _isToday(date);
    
    return InkWell(
      onTap: onToggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            // 日期信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isToday ? theme.colorScheme.primary : null,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '今日',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dailyStats.transactionCount}笔交易',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 当日盈亏
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(dailyStats.netProfit),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: netProfitColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dailyStats.profitableCount > 0) ...[
                      Icon(
                        LucideIcons.trendingUp,
                        size: 12,
                        color: colors.getColorByValue(1.0),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${dailyStats.profitableCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.getColorByValue(1.0),
                        ),
                      ),
                    ],
                    if (dailyStats.profitableCount > 0 && dailyStats.lossCount > 0)
                      const SizedBox(width: 8),
                    if (dailyStats.lossCount > 0) ...[
                      Icon(
                        LucideIcons.trendingDown,
                        size: 12,
                        color: colors.getColorByValue(-1.0),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${dailyStats.lossCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.getColorByValue(-1.0),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),
            // 展开/收起图标
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ProfitLossRecordCard(
              transaction: transaction,
              onTap: () => onTransactionTap(transaction),
              onEdit: () => onTransactionEdit(transaction),
              onDelete: () => onTransactionDelete(transaction),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: theme.colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '数据加载失败',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return '今日 ${date.month}月${date.day}日';
    } else if (date.isAtSameMomentAs(yesterday)) {
      return '昨日 ${date.month}月${date.day}日';
    } else {
      // 判断是否为本年
      if (date.year == now.year) {
        // 本年：只显示月日和星期
        return '${date.month}月${date.day}日 周${_getWeekdayName(date.weekday)}';
      } else {
        // 非本年：显示年月日和星期
        return '${date.year}年${date.month}月${date.day}日 周${_getWeekdayName(date.weekday)}';
      }
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAtSameMomentAs(today);
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