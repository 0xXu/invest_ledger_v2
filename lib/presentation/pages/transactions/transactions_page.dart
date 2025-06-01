import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/transaction.dart';

import '../../providers/transaction_provider.dart';
import '../../widgets/stock_investment_card.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/animated_card.dart';
import '../../utils/loading_utils.dart';

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
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易记录'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/transactions/search');
            },
            icon: const Icon(Icons.search),
            tooltip: '搜索交易',
          ),
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(transactionNotifierProvider);
            },
            loadingMessage: '正在刷新交易记录...',
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) => _TransactionsList(transactions: transactions),
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
          context.go('/transactions/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无交易记录',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '点击右下角的 + 按钮添加第一笔交易',
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
          delay: Duration(milliseconds: index * 30), // 减少延迟时间，更流畅
          duration: const Duration(milliseconds: 400), // 缩短动画时间
          curve: Curves.easeOutQuart, // 使用更流畅的曲线
          enableAnimation: true, // 所有卡片都启用动画
          enableScrollVisibility: false, // 完全禁用滚动可见性检测
          slideDirection: SlideDirection.fromBottom, // 从下方滑入更自然
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StockInvestmentCard(
              transaction: transaction,
              onTap: () {
                context.push('/transactions/${transaction.id}');
              },
              onEdit: () {
                context.push('/transactions/edit/${transaction.id}');
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
          title: const Text('删除交易'),
          content: Text('确定要删除这笔交易吗？此操作无法撤销。\n\n${transaction.stockName} (${transaction.stockCode})'),
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
                  }, '正在删除交易记录...');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('交易记录已删除')),
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
