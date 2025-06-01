import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoalProgressCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = progress['hasGoal'] as bool;

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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onSetGoal,
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
              '暂未设置$title',
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
    final targetAmount = progress['targetAmount'] as double;
    final actualAmount = progress['actualAmount'] as double;
    final completionRate = progress['completionRate'] as double;
    final timeProgress = progress['timeProgress'] as double;
    final status = progress['status'] as String;
    final lastYearComparison = progress['lastYearComparison'] as double;

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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEditGoal,
                  icon: const Icon(LucideIcons.settings, size: 16),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '目标完成度',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${completionRate.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (completionRate / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ],
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
