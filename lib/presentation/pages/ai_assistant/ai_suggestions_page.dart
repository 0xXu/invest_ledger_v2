import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../providers/ai_suggestion_provider.dart';
import '../../widgets/refresh_button.dart';

class AISuggestionsPage extends ConsumerWidget {
  const AISuggestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(userAISuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI投资建议'),
        actions: [
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(userAISuggestionsProvider);
            },
            loadingMessage: '正在刷新建议...',
            tooltip: '刷新',
          ),
        ],
      ),
      body: suggestionsAsync.when(
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无AI建议',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '使用AI分析功能获取投资建议',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    _getActionIcon(suggestion.analysis.action),
                    color: _getActionColor(suggestion.analysis.action),
                  ),
                  title: Text('${suggestion.analysis.stockName} (${suggestion.analysis.stockCode})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${suggestion.analysis.action.toUpperCase()} - ${(suggestion.analysis.confidence * 100).toStringAsFixed(1)}%',
                      ),
                      Text(
                        '创建时间: ${_formatDateTime(suggestion.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(suggestion.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(suggestion.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(suggestion.status),
                      ),
                    ),
                  ),
                  onTap: () {
                    // TODO: 导航到建议详情页面
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return LucideIcons.trendingUp;
      case 'sell':
        return LucideIcons.trendingDown;
      default:
        return LucideIcons.minus;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getStatusColor(AISuggestionStatus status) {
    switch (status) {
      case AISuggestionStatus.pending:
        return Colors.orange;
      case AISuggestionStatus.executed:
        return Colors.green;
      case AISuggestionStatus.ignored:
        return Colors.grey;
      case AISuggestionStatus.expired:
        return Colors.red;
    }
  }

  String _getStatusText(AISuggestionStatus status) {
    switch (status) {
      case AISuggestionStatus.pending:
        return '待处理';
      case AISuggestionStatus.executed:
        return '已执行';
      case AISuggestionStatus.ignored:
        return '已忽略';
      case AISuggestionStatus.expired:
        return '已过期';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}-${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
