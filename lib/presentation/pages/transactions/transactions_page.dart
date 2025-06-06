import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/transaction.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_status.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/stock_investment_card.dart';
import '../../widgets/profit_loss_record_card.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/animated_card.dart';
import '../../utils/loading_utils.dart';

// 记录显示模式
enum RecordDisplayMode {
  profitLoss, // 盈亏记录
  detailed,   // 详细交易记录
}

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重建

  // 当前显示模式，默认显示盈亏记录
  RecordDisplayMode _displayMode = RecordDisplayMode.profitLoss;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保活机制
    final transactionsAsync = ref.watch(transactionNotifierProvider);

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
      appBar: AppBar(
        title: Text(_displayMode == RecordDisplayMode.profitLoss ? '盈亏记录' : '交易记录'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildModeSelector(),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/transactions/search');
            },
            icon: const Icon(Icons.search),
            tooltip: '搜索记录',
          ),
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(transactionNotifierProvider);
            },
            loadingMessage: '正在刷新数据...',
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // 根据模式过滤交易记录
          final filteredTransactions = _filterTransactionsByMode(transactions);
          return _TransactionsList(
            transactions: filteredTransactions,
            displayMode: _displayMode,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              RefreshButton.filled(
                onRefresh: () async {
                  ref.invalidate(transactionNotifierProvider);
                },
                label: '重试',
                loadingMessage: '正在重新加载...',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final mode = _displayMode == RecordDisplayMode.profitLoss ? 'simple' : 'detailed';
          context.go('/transactions/add?mode=$mode');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建模式切换器
  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _displayMode = RecordDisplayMode.profitLoss;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _displayMode == RecordDisplayMode.profitLoss
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: _displayMode == RecordDisplayMode.profitLoss
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '盈亏记录',
                      style: TextStyle(
                        color: _displayMode == RecordDisplayMode.profitLoss
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: _displayMode == RecordDisplayMode.profitLoss
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _displayMode = RecordDisplayMode.detailed;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _displayMode == RecordDisplayMode.detailed
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: _displayMode == RecordDisplayMode.detailed
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '交易记录',
                      style: TextStyle(
                        color: _displayMode == RecordDisplayMode.detailed
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: _displayMode == RecordDisplayMode.detailed
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据模式过滤交易记录
  List<Transaction> _filterTransactionsByMode(List<Transaction> transactions) {
    switch (_displayMode) {
      case RecordDisplayMode.profitLoss:
        // 盈亏记录：显示所有有盈亏的交易（盈亏不为0的记录）
        return transactions.where((t) => t.profitLoss.toDouble() != 0.0).toList();
      case RecordDisplayMode.detailed:
        // 详细交易记录：显示所有交易
        return transactions;
    }
  }
}

class _TransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final RecordDisplayMode displayMode;

  const _TransactionsList({
    required this.transactions,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              displayMode == RecordDisplayMode.profitLoss
                  ? Icons.account_balance_wallet
                  : Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              displayMode == RecordDisplayMode.profitLoss
                  ? '暂无盈亏记录'
                  : '暂无交易记录',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              displayMode == RecordDisplayMode.profitLoss
                  ? '点击右下角的 + 按钮快速记录盈亏'
                  : '点击右下角的 + 按钮添加详细交易',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return AnimatedCard.fadeSlideIn(
          delay: Duration(milliseconds: index * 30), // 减少延迟时间，更流畅
          duration: const Duration(milliseconds: 400), // 缩短动画时间
          curve: Curves.easeOutQuart, // 使用更流畅的曲线
          enableAnimation: true, // 所有卡片都启用动画
          enableScrollVisibility: false, // 完全禁用滚动可见性检测
          slideDirection: SlideDirection.fromBottom, // 从下方滑入更自然
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: displayMode == RecordDisplayMode.profitLoss
                ? ProfitLossRecordCard(
                    transaction: transaction,
                    onTap: () {
                      context.push('/transactions/${transaction.id}');
                    },
                    onEdit: () {
                      context.push('/transactions/edit/${transaction.id}?mode=simple');
                    },
                    onDelete: () {
                      _showDeleteDialog(context, transaction, displayMode);
                    },
                  )
                : StockInvestmentCard(
                    transaction: transaction,
                    onTap: () {
                      context.push('/transactions/${transaction.id}');
                    },
                    onEdit: () {
                      context.push('/transactions/edit/${transaction.id}?mode=detailed');
                    },
                    onDelete: () {
                      _showDeleteDialog(context, transaction, displayMode);
                    },
                  ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Transaction transaction, RecordDisplayMode displayMode) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: Text(displayMode == RecordDisplayMode.profitLoss ? '删除盈亏记录' : '删除交易记录'),
          content: Text(
            displayMode == RecordDisplayMode.profitLoss
                ? '确定要删除这条盈亏记录吗？此操作无法撤销。\n\n${transaction.stockName}'
                : '确定要删除这笔交易吗？此操作无法撤销。\n\n${transaction.stockName} (${transaction.stockCode})'
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
                  }, displayMode == RecordDisplayMode.profitLoss
                      ? '正在删除盈亏记录...'
                      : '正在删除交易记录...');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(displayMode == RecordDisplayMode.profitLoss
                            ? '盈亏记录已删除'
                            : '交易记录已删除'),
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
      ),
    );
  }
}
