import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/transaction.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_status.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/profit_loss_record_card.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/animated_card.dart';
import '../../utils/loading_utils.dart';

class ProfitLossRecordsPage extends ConsumerStatefulWidget {
  const ProfitLossRecordsPage({super.key});

  @override
  ConsumerState<ProfitLossRecordsPage> createState() => _ProfitLossRecordsPageState();
}

class _ProfitLossRecordsPageState extends ConsumerState<ProfitLossRecordsPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    // 监听同步状态
    ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (previous, next) {
      next.whenData((status) {
        if (previous?.value?.state != SyncState.success &&
            status.state == SyncState.success) {
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
        title: const Text('盈亏记录'),
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
            loadingMessage: '正在刷新盈亏记录...',
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // 过滤出简单模式的记录（根据备注或其他标识）
          final profitLossRecords = transactions.where((t) => 
            _isSimpleModeRecord(t)
          ).toList();
          return _ProfitLossRecordsList(transactions: profitLossRecords);
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
          context.go('/transactions/add?mode=simple');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 判断是否为简单模式记录
  bool _isSimpleModeRecord(Transaction transaction) {
    // 简单模式的特征：
    // 1. 数量为1
    // 2. 备注包含"简单模式"
    // 3. 单价等于盈亏金额的绝对值
    return transaction.amount.toDouble().abs() == 1.0 &&
           (transaction.notes?.contains('简单模式') ?? false);
  }
}

class _ProfitLossRecordsList extends StatelessWidget {
  final List<Transaction> transactions;

  const _ProfitLossRecordsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无盈亏记录',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '点击右下角的 + 按钮快速记录盈亏',
              style: TextStyle(color: Colors.grey),
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
          delay: Duration(milliseconds: index * 30),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          enableAnimation: true,
          enableScrollVisibility: false,
          slideDirection: SlideDirection.fromBottom,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ProfitLossRecordCard(
              transaction: transaction,
              onTap: () {
                context.push('/transactions/${transaction.id}');
              },
              onEdit: () {
                context.push('/transactions/edit/${transaction.id}?mode=simple');
              },
              onDelete: () {
                _showDeleteDialog(context, transaction);
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: const Text('删除记录'),
          content: Text('确定要删除这条盈亏记录吗？此操作无法撤销。\n\n${transaction.stockName}'),
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
                      const SnackBar(content: Text('盈亏记录已删除')),
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
