import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../widgets/analysis/enhanced_analysis_details.dart';

class DetailedAnalysisPage extends ConsumerWidget {
  final AIAnalysisResult result;

  const DetailedAnalysisPage({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('详细分析 - ${result.stockCode}'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share),
            tooltip: '分享分析结果',
            onPressed: () {
              // TODO: 实现分享功能
            },
          ),
        ],
      ),
      body: result.detailedAnalysis != null
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 分析概览
                  _buildAnalysisOverview(context),
                  const SizedBox(height: 16),

                  // 详细分析组件
                  EnhancedAnalysisDetails(
                    result: result,
                    showReasoning: true,
                  ),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.fileX,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无详细分析数据',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请重新运行分析以获取详细数据',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalysisOverview(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart3, size: 20),
                const SizedBox(width: 8),
                Text(
                  '分析概览',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基本信息
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '股票代码',
                    result.stockCode,
                    LucideIcons.hash,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '股票名称',
                    result.stockName,
                    LucideIcons.building,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '分析时间',
                    _formatDateTime(result.analysisTime),
                    LucideIcons.clock,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Agent数量',
                    '${result.detailedAnalysis?.length ?? 0}个',
                    LucideIcons.users,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
