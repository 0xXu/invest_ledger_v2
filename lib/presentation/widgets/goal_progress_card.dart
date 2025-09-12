import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../data/models/investment_goal.dart';
import '../../core/utils/number_formatter.dart';
import '../providers/investment_goal_provider.dart';
import 'goal_setting_dialog.dart';

/// 目标进度卡片 - 显示月度/年度收益目标和进度
class GoalProgressCard extends ConsumerWidget {
  final String title;
  final double currentValue;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isMonthly; // true为月度，false为年度

  const GoalProgressCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isMonthly,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // 使用对应的单个目标provider
    final goalAsync = isMonthly 
      ? ref.watch(currentMonthlyGoalProvider)
      : ref.watch(currentYearlyGoalProvider);

    return goalAsync.when(
      data: (goal) => _buildCard(context, theme, goal),
      loading: () => _buildLoadingCard(theme),
      error: (_, __) => _buildCard(context, theme, null),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, InvestmentGoal? goal) {
    final targetValue = goal?.targetAmount.toDouble() ?? 0.0;
    
    final progress = targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    final progressPercentage = (progress * 100).toInt();
    
    // 根据进度确定圆环颜色
    final progressColor = _getProgressColor(progress);

    return GestureDetector(
      onTap: () => _showGoalSettingDialog(context, goal),
      child: Container(
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
                // 进度圆环
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(48, 48),
                        painter: _CircularProgressPainter(
                          progress: progress,
                          color: progressColor, // 使用进度相关的颜色
                        ),
                      ),
                      Center(
                        child: targetValue > 0 
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (progress >= 1.0) ...[
                                  Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: progressColor,
                                  ),
                                  const SizedBox(width: 2),
                                ]
                                else
                                  Text(
                                    '$progressPercentage%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: progressColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            )
                          : Icon(
                              LucideIcons.target,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              NumberFormatter.formatCurrency(currentValue, showSign: false),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
                if (targetValue > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress >= 1.0) ...[
                          Icon(
                            _getProgressStatusIcon(progress),
                            size: 10,
                            color: progressColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getProgressStatusText(progress),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: progressColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            LucideIcons.target,
                            size: 10,
                            color: progressColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '目标 ${NumberFormatter.formatCurrency(targetValue, showSign: false)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: progressColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '点击设置目标',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalSettingDialog(BuildContext context, InvestmentGoal? currentGoal) {
    showDialog(
      context: context,
      builder: (context) => GoalSettingDialog(
        currentGoal: currentGoal,
        isYearly: !isMonthly,
      ),
    );
  }

  /// 根据进度获取圆环颜色
  Color _getProgressColor(double progress) {
    if (progress >= 1.2) {
      // 超额完成20%以上：深绿色（卓越）
      return const Color(0xFF059669); // 深绿色
    } else if (progress >= 1.0) {
      // 达到或略微超过目标：绿色（成功）
      return const Color(0xFF16A34A); // 标准绿色
    } else if (progress >= 0.8) {
      // 接近目标(80%以上)：蓝色（良好进展）
      return const Color(0xFF2563EB); // 蓝色
    } else if (progress >= 0.5) {
      // 中等进展(50%-80%)：橙色（需要努力）
      return const Color(0xFFF59E0B); // 橙色
    } else {
      // 进展较少(<50%)：红色（需要关注）
      return const Color(0xFFDC2626); // 红色
    }
  }

  /// 根据进度获取状态文本
  String _getProgressStatusText(double progress) {
    if (progress >= 1.2) {
      return '超额完成'; 
    } else if (progress >= 1.0) {
      return '已完成';
    } else if (progress >= 0.8) {
      return '接近目标';
    } else if (progress >= 0.5) {
      return '进展中';
    } else {
      return '需要努力';
    }
  }

  /// 根据进度获取状态图标
  IconData _getProgressStatusIcon(double progress) {
    if (progress >= 1.2) {
      return LucideIcons.crown; // 王冠图标表示卓越
    } else if (progress >= 1.0) {
      return LucideIcons.checkCircle2; // 完成
    } else if (progress >= 0.8) {
      return LucideIcons.trendingUp; // 上升趋势
    } else if (progress >= 0.5) {
      return LucideIcons.activity; // 活动中
    } else {
      return LucideIcons.alertCircle; // 需要关注
    }
  }
}

/// 自定义圆形进度条绘制器
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 4.0;
    final double radius = size.width / 2 - strokeWidth / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 背景圆环
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆环
    if (progress > 0) {
      final Paint progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const double startAngle = -3.14159 / 2; // 从顶部开始
      final double sweepAngle = 2 * 3.14159 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _CircularProgressPainter ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
