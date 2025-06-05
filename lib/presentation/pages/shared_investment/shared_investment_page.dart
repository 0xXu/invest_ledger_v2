import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../data/models/shared_investment.dart';
import '../../providers/shared_investment_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/animated_card.dart';

class SharedInvestmentPage extends ConsumerStatefulWidget {
  const SharedInvestmentPage({super.key});

  @override
  ConsumerState<SharedInvestmentPage> createState() => _SharedInvestmentPageState();
}

class _SharedInvestmentPageState extends ConsumerState<SharedInvestmentPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sharedInvestmentsAsync = ref.watch(sharedInvestmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('共享投资'),
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(LucideIcons.search),
            tooltip: '搜索共享投资',
          ),
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(sharedInvestmentNotifierProvider);
            },
            loadingMessage: '正在刷新共享投资...',
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: sharedInvestmentsAsync.when(
        data: (sharedInvestments) {
          final filteredInvestments = _filterInvestments(sharedInvestments);
          return _SharedInvestmentsList(
            sharedInvestments: filteredInvestments,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              RefreshButton.filled(
                onRefresh: () async {
                  ref.invalidate(sharedInvestmentNotifierProvider);
                },
                label: '重试',
                loadingMessage: '正在重新加载...',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateSharedInvestmentDialog(context);
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('创建共享投资'),
      ),
    );
  }

  void _showCreateSharedInvestmentDialog(BuildContext context) {
    context.push('/shared-investment/create');
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索共享投资'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入投资名称、股票代码或股票名称',
            prefixIcon: Icon(LucideIcons.search),
          ),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  List<SharedInvestment> _filterInvestments(List<SharedInvestment> investments) {
    if (_searchQuery.isEmpty) {
      return investments;
    }

    final query = _searchQuery.toLowerCase();
    return investments.where((investment) {
      return investment.name.toLowerCase().contains(query) ||
          investment.stockCode.toLowerCase().contains(query) ||
          investment.stockName.toLowerCase().contains(query);
    }).toList();
  }
}

class _SharedInvestmentsList extends ConsumerWidget {
  final List<SharedInvestment> sharedInvestments;

  const _SharedInvestmentsList({required this.sharedInvestments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sharedInvestments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无共享投资',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '点击右下角的按钮创建第一个共享投资',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sharedInvestments.length,
      itemBuilder: (context, index) {
        final sharedInvestment = sharedInvestments[index];
        return AnimatedCard.fadeSlideIn(
          delay: Duration(milliseconds: index * 30),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          enableAnimation: true,
          enableScrollVisibility: false,
          slideDirection: SlideDirection.fromLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SharedInvestmentCard(sharedInvestment: sharedInvestment),
          ),
        );
      },
    );
  }
}

class _SharedInvestmentCard extends ConsumerWidget {
  final SharedInvestment sharedInvestment;

  const _SharedInvestmentCard({required this.sharedInvestment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) {
        // 计算总盈亏
        final totalProfitLoss = sharedInvestment.participants.fold(
          0.0,
          (sum, participant) => sum + participant.profitLoss.toDouble(),
        );

        final statusColor = _getStatusColor(sharedInvestment.status);
        final profitLossColor = colors.getColorByValue(totalProfitLoss);

        return Card(
          child: InkWell(
            onTap: () {
              context.push('/shared-investment/${sharedInvestment.id}');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.users,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sharedInvestment.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${sharedInvestment.stockName} (${sharedInvestment.stockCode})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(sharedInvestment.status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 投资信息
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          label: '总投资',
                          value: '¥${sharedInvestment.totalAmount.toStringAsFixed(2)}',
                          icon: LucideIcons.wallet,
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          label: '参与人数',
                          value: '${sharedInvestment.participants.length}人',
                          icon: LucideIcons.users,
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          label: '总盈亏',
                          value: '¥${totalProfitLoss.abs().toStringAsFixed(2)}',
                          icon: totalProfitLoss >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                          valueColor: profitLossColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 创建时间
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '创建于 ${DateFormat('yyyy-MM-dd').format(sharedInvestment.createdDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(child: SizedBox(height: 120)),
      error: (_, __) => const Card(child: SizedBox(height: 120)),
    );
  }

  Color _getStatusColor(SharedInvestmentStatus status) {
    switch (status) {
      case SharedInvestmentStatus.active:
        return const Color(0xFF10B981); // Green
      case SharedInvestmentStatus.completed:
        return const Color(0xFF6B7280); // Gray
      case SharedInvestmentStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _getStatusText(SharedInvestmentStatus status) {
    switch (status) {
      case SharedInvestmentStatus.active:
        return '进行中';
      case SharedInvestmentStatus.completed:
        return '已完成';
      case SharedInvestmentStatus.cancelled:
        return '已取消';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: valueColor ?? theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
