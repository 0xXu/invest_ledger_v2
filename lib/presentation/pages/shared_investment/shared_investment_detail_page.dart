import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../data/models/shared_investment.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../providers/shared_investment_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/dialogs/complete_investment_dialog.dart';
import '../../widgets/dialogs/cancel_investment_dialog.dart';

class SharedInvestmentDetailPage extends ConsumerStatefulWidget {
  final String sharedInvestmentId;

  const SharedInvestmentDetailPage({
    super.key,
    required this.sharedInvestmentId,
  });

  @override
  ConsumerState<SharedInvestmentDetailPage> createState() => _SharedInvestmentDetailPageState();
}

class _SharedInvestmentDetailPageState extends ConsumerState<SharedInvestmentDetailPage> {
  @override
  Widget build(BuildContext context) {
    final sharedInvestmentsAsync = ref.watch(sharedInvestmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('共享投资详情'),
        actions: [
          IconButton(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(LucideIcons.edit),
            tooltip: '编辑',
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle),
                    SizedBox(width: 8),
                    Text('标记为完成'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(LucideIcons.xCircle),
                    SizedBox(width: 8),
                    Text('取消投资'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(sharedInvestmentNotifierProvider);
            },
            loadingMessage: '正在刷新...',
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: sharedInvestmentsAsync.when(
        data: (sharedInvestments) {
          final sharedInvestment = sharedInvestments
              .where((si) => si.id == widget.sharedInvestmentId)
              .firstOrNull;

          if (sharedInvestment == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('共享投资不存在'),
                ],
              ),
            );
          }

          return _SharedInvestmentDetailContent(sharedInvestment: sharedInvestment);
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
    );
  }

  void _showEditDialog(BuildContext context) {
    context.push('/shared-investment/${widget.sharedInvestmentId}/edit');
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'complete':
        _markAsCompleted(context);
        break;
      case 'cancel':
        _cancelInvestment(context);
        break;
      case 'delete':
        _deleteInvestment(context);
        break;
    }
  }

  void _markAsCompleted(BuildContext context) async {
    final sharedInvestmentsAsync = ref.read(sharedInvestmentNotifierProvider);
    if (!sharedInvestmentsAsync.hasValue) return;

    final sharedInvestment = sharedInvestmentsAsync.value!
        .where((si) => si.id == widget.sharedInvestmentId)
        .firstOrNull;

    if (sharedInvestment == null) return;

    showDialog(
      context: context,
      builder: (context) => CompleteInvestmentDialog(
        sharedInvestment: sharedInvestment,
        onComplete: (sellAmount, participantProfitLoss) async {
          try {
            await ref.read(sharedInvestmentNotifierProvider.notifier)
                .completeSharedInvestmentWithCustomProfitLoss(
              widget.sharedInvestmentId,
              sellAmount,
              participantProfitLoss,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('投资已完成'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('完成失败: $e')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _cancelInvestment(BuildContext context) async {
    final sharedInvestmentsAsync = ref.read(sharedInvestmentNotifierProvider);
    if (!sharedInvestmentsAsync.hasValue) return;

    final sharedInvestment = sharedInvestmentsAsync.value!
        .where((si) => si.id == widget.sharedInvestmentId)
        .firstOrNull;

    if (sharedInvestment == null) return;

    showDialog(
      context: context,
      builder: (context) => CancelInvestmentDialog(
        sharedInvestment: sharedInvestment,
        onCancel: (reason) async {
          try {
            await ref.read(sharedInvestmentNotifierProvider.notifier)
                .cancelSharedInvestment(widget.sharedInvestmentId, reason: reason);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('投资已取消'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('取消失败: $e')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteInvestment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.trash2, color: Colors.red),
            SizedBox(width: 12),
            Text('删除投资'),
          ],
        ),
        content: const Text(
          '确定要删除这个共享投资吗？\n\n'
          '删除后将无法恢复，相关的交易记录也会被删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await ref.read(sharedInvestmentNotifierProvider.notifier)
                    .deleteSharedInvestment(widget.sharedInvestmentId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(LucideIcons.checkCircle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('投资已删除'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop(); // 返回上一页
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('删除失败: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}

class _SharedInvestmentDetailContent extends ConsumerWidget {
  final SharedInvestment sharedInvestment;

  const _SharedInvestmentDetailContent({required this.sharedInvestment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedCardList(
          staggerDelay: const Duration(milliseconds: 100),
          animationType: CardAnimationType.fadeSlideIn,
          slideDirection: SlideDirection.fromBottom,
          enableScrollAnimation: true,
          children: [
            // 基本信息卡片
            _buildBasicInfoCard(theme, colors),
            const SizedBox(height: 16),

            // 投资统计卡片
            _buildStatsCard(theme, colors),
            const SizedBox(height: 16),

            // 参与者列表卡片
            _buildParticipantsCard(theme, colors),
            const SizedBox(height: 16),

            // 备注信息卡片
            if (sharedInvestment.notes?.isNotEmpty == true)
              _buildNotesCard(theme),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Icon(Icons.error)),
    );
  }

  Widget _buildBasicInfoCard(ThemeData theme, ProfitLossColors colors) {
    final statusColor = _getStatusColor(sharedInvestment.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  child: Text(
                    sharedInvestment.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
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

            // 股票信息
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${sharedInvestment.stockName} (${sharedInvestment.stockCode})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
                const SizedBox(width: 8),
                Text(
                  '创建于 ${DateFormat('yyyy年MM月dd日').format(sharedInvestment.createdDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, ProfitLossColors colors) {
    final totalProfitLoss = sharedInvestment.participants.fold(
      0.0,
      (sum, participant) => sum + participant.profitLoss.toDouble(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '投资统计',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    '总投资金额',
                    '¥${sharedInvestment.totalAmount.toStringAsFixed(2)}',
                    LucideIcons.wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    '总股数',
                    '${sharedInvestment.totalShares.toStringAsFixed(0)}股',
                    LucideIcons.pieChart,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    '参与人数',
                    '${sharedInvestment.participants.length}人',
                    LucideIcons.users,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    '总盈亏',
                    '${totalProfitLoss >= 0 ? '+' : ''}¥${totalProfitLoss.toStringAsFixed(2)}',
                    totalProfitLoss >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    colors.getColorByValue(totalProfitLoss),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(ThemeData theme, ProfitLossColors colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '参与者 (${sharedInvestment.participants.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...sharedInvestment.participants.map((participant) {
              final profitLoss = participant.profitLoss.toDouble();
              final profitLossColor = colors.getColorByValue(profitLoss);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        participant.userName.isNotEmpty
                            ? participant.userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '投资: ¥${participant.investmentAmount.toStringAsFixed(2)} | '
                            '股数: ${participant.shares.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${profitLoss >= 0 ? '+' : ''}¥${profitLoss.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: profitLossColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          profitLoss >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                          color: profitLossColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '备注',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sharedInvestment.notes!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
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
