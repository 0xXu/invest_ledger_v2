import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoalProgressCard extends StatefulWidget {
  final String title;
  final Map<String, dynamic> progress;
  final VoidCallback? onSetGoal;
  final VoidCallback? onEditGoal;

  const GoalProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.onSetGoal,
    this.onEditGoal,
  });

  @override
  State<GoalProgressCard> createState() => _GoalProgressCardState();
}

class _GoalProgressCardState extends State<GoalProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // 进度条动画控制器
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 进度条动画
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // 启动动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GoalProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果进度数据发生变化，重新启动动画
    if (oldWidget.progress != widget.progress) {
      final hasGoal = widget.progress['hasGoal'] as bool? ?? false;
      if (hasGoal) {
        // 重新启动进度动画
        _progressController.reset();
        _progressController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = widget.progress['hasGoal'] as bool;

    if (!hasGoal) {
      return _buildNoGoalCard(context, theme);
    }

    return _buildGoalCard(context, theme);
  }

  Widget _buildNoGoalCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.target, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onSetGoal,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('设置目标'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '暂未设置${widget.title}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, ThemeData theme) {
    final targetAmount = widget.progress['targetAmount'] as double;
    final actualAmount = widget.progress['actualAmount'] as double;
    final completionRate = widget.progress['completionRate'] as double;
    final timeProgress = widget.progress['timeProgress'] as double;
    final status = widget.progress['status'] as String;
    final lastYearComparison = widget.progress['lastYearComparison'] as double;

    final progressColor = _getProgressColor(completionRate);
    final statusInfo = _getStatusInfo(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(LucideIcons.target, color: progressColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onEditGoal,
                  icon: const Icon(LucideIcons.settings, size: 16),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Enhanced Progress bar with animation
            _buildAnimatedProgressBar(
              context,
              theme,
              completionRate,
              progressColor,
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '目标',
                    '¥${targetAmount.toStringAsFixed(0)}',
                    Colors.blue,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '实际',
                    '¥${actualAmount.toStringAsFixed(0)}',
                    actualAmount >= 0 ? Colors.green : Colors.red,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '时间进度',
                    '${timeProgress.toStringAsFixed(1)}%',
                    Colors.orange,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status and comparison
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo['icon'],
                        size: 12,
                        color: statusInfo['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo['text'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusInfo['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (lastYearComparison != 0)
                  Row(
                    children: [
                      Icon(
                        lastYearComparison > 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 14,
                        color: lastYearComparison > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '同比${lastYearComparison > 0 ? '+' : ''}${lastYearComparison.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: lastYearComparison > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建动画进度条
  Widget _buildAnimatedProgressBar(
    BuildContext context,
    ThemeData theme,
    double completionRate,
    Color progressColor,
  ) {
    final normalizedProgress = (completionRate / 100).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final animatedProgress = normalizedProgress * _progressAnimation.value;

        return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和百分比
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '目标完成度',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: progressColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: progressColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${completionRate.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 自定义进度条
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          // 背景
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                          ),

                          // 进度条
                          FractionallySizedBox(
                            widthFactor: animatedProgress,
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    progressColor.withValues(alpha: 0.8),
                                    progressColor,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: progressColor.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 高光效果
                          if (animatedProgress > 0)
                            FractionallySizedBox(
                              widthFactor: animatedProgress,
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 进度指示器（如果完成度很高）
                  if (completionRate >= 100) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.checkCircle,
                          size: 16,
                          color: progressColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '目标已完成！',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: progressColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else if (completionRate >= 80) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.zap,
                          size: 16,
                          color: progressColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '即将完成目标！',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: progressColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
      },
    );
  }

  Color _getProgressColor(double completionRate) {
    if (completionRate >= 100) return Colors.green;
    if (completionRate >= 80) return Colors.blue;
    if (completionRate >= 50) return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'conservative':
        return {
          'text': '过于保守',
          'color': Colors.blue,
          'icon': LucideIcons.trendingDown,
        };
      case 'aggressive':
        return {
          'text': '过于激进',
          'color': Colors.red,
          'icon': LucideIcons.trendingUp,
        };
      case 'reasonable':
        return {
          'text': '进度合理',
          'color': Colors.green,
          'icon': LucideIcons.checkCircle,
        };
      default:
        return {
          'text': '未知',
          'color': Colors.grey,
          'icon': LucideIcons.helpCircle,
        };
    }
  }
}
