import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/transaction.dart';
import '../../../data/services/transaction_stats_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_status.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../widgets/hero_stats_section.dart';
import '../../widgets/smart_filter_bar.dart';
import '../../widgets/grouped_transactions_list.dart';
import '../../widgets/profit_loss_record_card.dart';
import '../../widgets/refresh_button.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重建

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保活机制
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final filterState = ref.watch(filterStateProvider);

    // 监听同步状态，当同步完成时自动刷新数据
    ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (previous, next) {
      next.whenData((status) {
        if (previous?.value?.state != SyncState.success &&
            status.state == SyncState.success) {
          // 同步刚刚完成，刷新交易数据
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.invalidate(transactionNotifierProvider);
            }
          });
        }
      });
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('盈亏记录'),
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.push('/transactions/search');
            },
            icon: const Icon(LucideIcons.search),
            tooltip: '搜索记录',
          ),
          IconButton(
            onPressed: () {
              context.go('/transactions/add?mode=simple');
            },
            icon: const Icon(LucideIcons.plus),
            tooltip: '添加盈亏记录',
          ),
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(transactionNotifierProvider);
              ref.invalidate(comprehensiveStatsProvider);
            },
            loadingMessage: '正在刷新数据...',
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionNotifierProvider);
          ref.invalidate(comprehensiveStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Hero 统计概览区域
            SliverToBoxAdapter(
              child: HeroStatsSection(
                onTap: () {
                  context.push('/analytics');
                },
              ),
            ),
            // 智能筛选工具栏
            SliverToBoxAdapter(
              child: SmartFilterBar(
                onStocksChanged: (stocks) {
                  // 股票筛选变化时的处理逻辑已在组件内部处理
                },
                onSearchPressed: () {
                  context.push('/transactions/search');
                },
              ),
            ),
            // 主要内容区域
            transactionsAsync.when(
              data: (allTransactions) {
                // 应用筛选器和排序
                final filteredTransactions = _applyFilters(allTransactions, filterState);
                // 只显示有盈亏的交易（盈亏不为0的记录）
                final displayTransactions = filteredTransactions.where((t) => t.profitLoss.toDouble() != 0.0).toList();
                
                if (displayTransactions.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击右上角的 + 按钮快速记录盈亏',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // 使用现有的GroupedTransactionsList组件
                return SliverFillRemaining(
                  child: GroupedTransactionsList(
                    transactions: displayTransactions,
                    displayMode: RecordDisplayMode.profitLoss,
                    onRefresh: () {
                      ref.invalidate(transactionNotifierProvider);
                      ref.invalidate(comprehensiveStatsProvider);
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () async {
                            ref.invalidate(transactionNotifierProvider);
                            ref.invalidate(comprehensiveStatsProvider);
                          },
                          icon: const Icon(LucideIcons.refreshCw),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 应用筛选器和排序
  List<Transaction> _applyFilters(List<Transaction> transactions, FilterState filterState) {
    final service = TransactionStatsService();
    
    DateTime? startDate;
    DateTime? endDate;
    
    // 根据时间范围设置开始和结束日期
    final now = DateTime.now();
    switch (filterState.timeRange) {
      case TimeRange.today:
        final today = DateTime(now.year, now.month, now.day);
        startDate = today;
        endDate = today.add(const Duration(days: 1));
        break;
      case TimeRange.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case TimeRange.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case TimeRange.all:
        // 不设置时间筛选
        break;
    }
    
    // 先应用筛选
    List<Transaction> filteredTransactions = service.filterTransactions(
      transactions,
      startDate: startDate,
      endDate: endDate,
      stockNames: filterState.selectedStocks.isNotEmpty ? filterState.selectedStocks : null,
      profitLossFilter: filterState.profitLossFilter,
    );
    
    // 然后应用排序
    switch (filterState.sortOption) {
      case SortOption.dateDesc:
        filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        filteredTransactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.profitDesc:
        filteredTransactions.sort((a, b) => b.profitLoss.compareTo(a.profitLoss));
        break;
      case SortOption.profitAsc:
        filteredTransactions.sort((a, b) => a.profitLoss.compareTo(b.profitLoss));
        break;
    }
    
    return filteredTransactions;
  }
}