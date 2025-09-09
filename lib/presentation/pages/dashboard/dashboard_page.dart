import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

import '../../../data/models/transaction.dart';
import '../../../data/models/investment_goal.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_goal_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/profit_loss_text.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/charts/profit_loss_chart.dart';
import '../../widgets/goal_progress_card.dart';

// For the ChartData class
class ChartData {
  final String label;
  final double value;
  ChartData({required this.label, required this.value});
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重建

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保活机制
    final authState = ref.watch(authServiceProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final statsAsync = ref.watch(transactionStatsProvider);

    // 监听同步状态，当同步完成时自动刷新数据
    ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (previous, next) {
      next.whenData((status) {
        if (previous?.value?.state != SyncState.success &&
            status.state == SyncState.success) {
          // 同步刚刚完成，刷新所有数据
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.invalidate(transactionNotifierProvider);
              ref.invalidate(transactionStatsProvider);
              ref.invalidate(monthlyGoalProgressProvider);
              ref.invalidate(yearlyGoalProgressProvider);
            }
          });
        }
      });
    });



    // 如果用户未登录，重新导航到登录页面
    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/auth/login');
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }



    return Scaffold(
      appBar: AppBar(
        title: Text('投资概览 - ${_getUserDisplayName(authState.user!)}'),
        actions: [
          // 同步状态组件
          const SyncStatusWidget(),
          const SizedBox(width: 8),
          RefreshButton.icon(
            onRefresh: () async {
              // 模拟网络延迟
              await Future.delayed(const Duration(seconds: 1));
              ref.invalidate(transactionNotifierProvider);
              ref.invalidate(transactionStatsProvider);
              ref.invalidate(monthlyGoalProgressProvider);
              ref.invalidate(yearlyGoalProgressProvider);
            },
            loadingMessage: '正在刷新数据...',
            tooltip: '刷新数据',
          ),
          // 设置菜单
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            tooltip: '更多选项',
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.go('/settings');
                  break;
                case 'import-export':
                  context.go('/import-export');
                  break;
                case 'shared-investment':
                  context.go('/shared-investment');
                  break;
                case 'logout':
                  _showLogoutDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(LucideIcons.settings),
                    SizedBox(width: 12),
                    Text('设置'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import-export',
                child: Row(
                  children: [
                    Icon(LucideIcons.download),
                    SizedBox(width: 12),
                    Text('导入导出'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'shared-investment',
                child: Row(
                  children: [
                    Icon(LucideIcons.users),
                    SizedBox(width: 12),
                    Text('共享投资'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, color: Colors.red),
                    SizedBox(width: 12),
                    Text('退出登录', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) => _DashboardContent(
          transactions: transactions,
          statsAsync: statsAsync,
        ),
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
                  ref.invalidate(transactionNotifierProvider);
                  ref.invalidate(transactionStatsProvider);
                },
                label: '重试',
                loadingMessage: '正在重新加载...',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// 获取用户显示名称，优先显示用户名，没有用户名则显示邮箱
  String _getUserDisplayName(User user) {
    // 尝试从用户元数据中获取显示名称
    final displayName = user.userMetadata?['display_name'] as String?;
    final name = user.userMetadata?['name'] as String?;

    // 优先使用display_name，然后是name，最后是email
    if (displayName != null && displayName.isNotEmpty && displayName != user.email) {
      return displayName;
    }

    if (name != null && name.isNotEmpty && name != user.email) {
      return name;
    }

    // 如果没有有效的用户名，返回邮箱
    return user.email ?? 'Unknown User';
  }

  /// 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authServiceProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth/quick-login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  /// 构建悬浮操作按钮
  Widget _buildFloatingActionButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 记录盈利
        FloatingActionButton(
          heroTag: "profit",
          onPressed: () {
            context.go('/transactions/add?mode=simple&from=dashboard&type=profit');
          },
          backgroundColor: const Color(0xFF16A34A),
          child: const Icon(LucideIcons.trendingUp, color: Colors.white),
          tooltip: '记录盈利',
        ),
        const SizedBox(height: 16),
        // 记录亏损
        FloatingActionButton(
          heroTag: "loss",
          onPressed: () {
            context.go('/transactions/add?mode=simple&from=dashboard&type=loss');
          },
          backgroundColor: const Color(0xFFDC2626),
          child: const Icon(LucideIcons.trendingDown, color: Colors.white),
          tooltip: '记录亏损',
        ),
      ],
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final List<Transaction> transactions;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  const _DashboardContent({
    required this.transactions,
    required this.statsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏆 英雄区域 - 突出净收益状态
            statsAsync.when(
              data: (stats) => _ModernHeroSection(stats: stats),
              loading: () => _HeroSkeleton(),
              error: (error, stack) => _HeroError(error: error.toString()),
            ),
            const SizedBox(height: 24),

            // 📊 核心指标网格 - 4个关键指标
            statsAsync.when(
              data: (stats) => _CoreMetricsGrid(
                stats: stats, 
                transactions: transactions,
              ),
              loading: () => _MetricsGridSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // 📈 收益趋势图表
            if (transactions.isNotEmpty) ...[
              _TrendChartSection(transactions: transactions),
              const SizedBox(height: 26),
            ],

            // 🎯 最近交易概览 - 展示最近3笔重要交易
            if (transactions.isNotEmpty) ...[
              _RecentTransactionsSection(transactions: transactions),
              const SizedBox(height: 20),
            ] else
              _EmptyStateSection(),
          ],
        ),
      ),
    );
  }
}

// 🏆 现代化英雄区域 - 突出投资总览
class _ModernHeroSection extends ConsumerWidget {
  final Map<String, dynamic> stats;

  const _ModernHeroSection({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);
    final theme = Theme.of(context);
    
    final netProfit = (stats['netProfit'] as num?)?.toDouble() ?? 0.0;
    final roi = (stats['roi'] as num?)?.toDouble() ?? 0.0;
    final totalInvestment = (stats['totalInvestment'] as num?)?.toDouble() ?? 0.0;

    return colorsAsync.when(
      data: (colors) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.getColorByValue(netProfit).withValues(alpha: 0.08),
              colors.getColorByValue(netProfit).withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.getColorByValue(netProfit).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.getColorByValue(netProfit).withValues(alpha: 0.1),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.getColorByValue(netProfit).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      netProfit >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: colors.getColorByValue(netProfit),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '投资总净收益',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          netProfit >= 0 ? '🎉 投资表现优秀' : '📈 继续加油投资',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.getColorByValue(netProfit),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 主要数据展示
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfitLossAmountText(
                          amount: netProfit,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 42,
                            height: 1.1,
                          ),
                          showIcon: false,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.getColorByValue(roi).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.getColorByValue(roi).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    roi >= 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                    size: 14,
                                    color: colors.getColorByValue(roi),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ROI ${roi.toStringAsFixed(1)}%',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.getColorByValue(roi),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => _HeroSkeleton(),
      error: (_, __) => _HeroError(error: '数据加载失败'),
    );
  }
}

// 📊 核心指标网格 - 2x2布局
class _CoreMetricsGrid extends ConsumerWidget {
  final Map<String, dynamic> stats;
  final List<Transaction> transactions; // 添加交易数据

  const _CoreMetricsGrid({
    required this.stats,
    required this.transactions, // 添加必需参数
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);
    final now = DateTime.now();
    
    final winRate = (stats['winRate'] as num?)?.toDouble() ?? 0.0;
    
    // 计算时间维度统计
    final monthlyStats = _calculateMonthlyStats(now);
    final yearlyStats = _calculateYearlyStats(now);

    return colorsAsync.when(
      data: (colors) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: '交易胜率',
                  value: '${winRate.toStringAsFixed(1)}%',
                  subtitle: winRate >= 70 ? '表现优秀' : winRate >= 50 ? '表现良好' : '需要优化',
                  icon: LucideIcons.target,
                  color: winRate >= 50 ? colors.getProfitColor() : colors.getLossColor(),
                  trend: winRate >= 50 ? '表现优秀' : '需要提升',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GoalProgressCard(
                  title: '本月收益',
                  currentValue: monthlyStats,
                  subtitle: DateFormat('MM月').format(now),
                  icon: LucideIcons.calendar,
                  color: colors.getColorByValue(monthlyStats),
                  isMonthly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GoalProgressCard(
                  title: '本年收益',
                  currentValue: yearlyStats,
                  subtitle: '${now.year}年累计',
                  icon: LucideIcons.calendarDays,
                  color: colors.getColorByValue(yearlyStats),
                  isMonthly: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: '总亏损额',
                  value: '¥${_getTotalLossAmount().toStringAsFixed(0)}',
                  subtitle: '累计亏损金额',
                  icon: LucideIcons.alertTriangle,
                  color: colors.getLossColor(),
                  trend: '风险提醒',
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => _MetricsGridSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  // 计算月度收益
  double _calculateMonthlyStats(DateTime now) {
    final currentMonth = DateFormat('yyyy-MM').format(now);
    return transactions
        .where((transaction) => DateFormat('yyyy-MM').format(transaction.date) == currentMonth)
        .fold(0.0, (sum, transaction) => sum + transaction.profitLoss.toDouble());
  }
  
  // 计算年度收益
  double _calculateYearlyStats(DateTime now) {
    return transactions
        .where((transaction) => transaction.date.year == now.year)
        .fold(0.0, (sum, transaction) => sum + transaction.profitLoss.toDouble());
  }
  
  // 计算总亏损金额
  double _getTotalLossAmount() {
    return transactions
        .where((transaction) => transaction.profitLoss.toDouble() < 0)
        .fold(0.0, (sum, transaction) => sum + transaction.profitLoss.toDouble().abs());
  }
}

// 指标卡片组件
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trend;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// 📈 趋势图表区域
class _TrendChartSection extends StatelessWidget {
  final List<Transaction> transactions;

  const _TrendChartSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.trendingUp,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '收益趋势分析',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '最近6个月',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    context.go('/analytics');
                  },
                  child: const Text('详细分析'),
                ),
              ],
            ),
          ),
          Container(
            height: 240,
            padding: const EdgeInsets.only(bottom: 16),
            child: ProfitLossChart(
              transactions: transactions,
              title: '',
            ),
          ),
        ],
      ),
    );
  }
}

// 🎯 最近交易概览
class _RecentTransactionsSection extends ConsumerWidget {
  final List<Transaction> transactions;

  const _RecentTransactionsSection({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);
    
    final recentTransactions = transactions.take(3).toList();

    return colorsAsync.when(
      data: (colors) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.clock,
                      color: Colors.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '最近交易',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.go('/transactions');
                    },
                    child: const Text('查看全部'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...recentTransactions.asMap().entries.map((entry) {
                final index = entry.key;
                final transaction = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < recentTransactions.length - 1 ? 12 : 0),
                  child: _RecentTransactionItem(
                    transaction: transaction,
                    colors: colors,
                    onTap: () {
                      context.push('/transactions/${transaction.id}');
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox(height: 200),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// 最近交易项目
class _RecentTransactionItem extends StatelessWidget {
  final Transaction transaction;
  final ProfitLossColors colors;
  final VoidCallback onTap;

  const _RecentTransactionItem({
    required this.transaction,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.getColorByValue(transaction.profitLoss.toDouble()).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.getColorByValue(transaction.profitLoss.toDouble()).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.getColorByValue(transaction.profitLoss.toDouble()).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.profitLoss >= Decimal.zero ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: colors.getColorByValue(transaction.profitLoss.toDouble()),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.stockName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MM月dd日 HH:mm').format(transaction.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ProfitLossAmountText(
                  amount: transaction.profitLoss.toDouble(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  showIcon: false,
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.amount}股',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 🎪 空状态组件
class _EmptyStateSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.indigo[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                LucideIcons.barChart3,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🚀 开始您的投资之旅',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '记录您的第一笔交易，开始追踪投资表现。\n我们将为您提供详细的分析和洞察。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/transactions/add?mode=simple&from=dashboard&type=profit');
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('记录第一笔交易'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 💀 骨架屏组件
class _HeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  final String error;
  
  const _HeroError({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.red[400], size: 32),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

