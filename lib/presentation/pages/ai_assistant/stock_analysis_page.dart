import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai_analysis/ai_analysis_page.dart';

class StockAnalysisPage extends ConsumerWidget {
  const StockAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 直接重定向到新的AI分析页面
    return const AIAnalysisPage();
  }
}
