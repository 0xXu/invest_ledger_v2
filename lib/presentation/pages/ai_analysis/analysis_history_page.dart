import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../widgets/refresh_button.dart';

class AnalysisHistoryPage extends ConsumerWidget {
  const AnalysisHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这里应该有一个历史记录的provider，暂时使用占位符
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析历史'),
        actions: [
          RefreshButton.icon(
            onRefresh: () async {
              // TODO: 刷新历史记录
            },
            loadingMessage: '正在刷新历史记录...',
            tooltip: '刷新',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '分析历史功能开发中',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '即将支持查看历史分析记录',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
