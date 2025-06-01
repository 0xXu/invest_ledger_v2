import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/ai_analysis_result.dart';
import 'technical_analysis_widget.dart';
import 'fundamental_analysis_widget.dart';

class EnhancedAnalysisDetails extends StatefulWidget {
  final AIAnalysisResult result;
  final bool showReasoning;

  const EnhancedAnalysisDetails({
    super.key,
    required this.result,
    required this.showReasoning,
  });

  @override
  State<EnhancedAnalysisDetails> createState() => _EnhancedAnalysisDetailsState();
}

class _EnhancedAnalysisDetailsState extends State<EnhancedAnalysisDetails>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabCount = _getTabCount();
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    int count = 1; // Always have overview tab
    if (widget.result.detailedAnalysis?.isNotEmpty == true) count++;
    if (widget.result.workflowFlow != null) count++;
    if (widget.result.llmInteractions?.isNotEmpty == true) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: _buildTabs(),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            isScrollable: true,
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        SizedBox(
          height: 600, // Fixed height for tab content
          child: TabBarView(
            controller: _tabController,
            children: _buildTabViews(),
          ),
        ),
      ],
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      const Tab(
        icon: Icon(LucideIcons.barChart3, size: 18),
        text: '分析概览',
      ),
    ];

    if (widget.result.detailedAnalysis?.isNotEmpty == true) {
      tabs.add(const Tab(
        icon: Icon(LucideIcons.users, size: 18),
        text: 'Agent详情',
      ));
    }

    if (widget.result.workflowFlow != null) {
      tabs.add(const Tab(
        icon: Icon(LucideIcons.gitBranch, size: 18),
        text: '工作流程',
      ));
    }

    if (widget.result.llmInteractions?.isNotEmpty == true) {
      tabs.add(const Tab(
        icon: Icon(LucideIcons.messageSquare, size: 18),
        text: 'AI交互',
      ));
    }

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _buildOverviewTab(),
    ];

    if (widget.result.detailedAnalysis?.isNotEmpty == true) {
      views.add(_buildAgentDetailsTab());
    }

    if (widget.result.workflowFlow != null) {
      views.add(_buildWorkflowTab());
    }

    if (widget.result.llmInteractions?.isNotEmpty == true) {
      views.add(_buildLLMInteractionsTab());
    }

    return views;
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Analysis Overview
          _buildBasicAnalysisCard(),
          const SizedBox(height: 16),

          // Agent Signals Summary
          _buildAgentSignalsSummary(),
          const SizedBox(height: 16),

          // Reasoning Summary
          if (widget.showReasoning) _buildReasoningSummary(),
        ],
      ),
    );
  }

  Widget _buildAgentDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.result.detailedAnalysis!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAgentDetailCard(entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWorkflowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWorkflowSummary(),
          const SizedBox(height: 16),
          _buildWorkflowTimeline(),
        ],
      ),
    );
  }

  Widget _buildLLMInteractionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.result.llmInteractions!.map((interaction) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildLLMInteractionCard(interaction),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBasicAnalysisCard() {
    final actionColor = _getActionColor(widget.result.action);
    final actionIcon = _getActionIcon(widget.result.action);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.target, size: 24, color: actionColor),
                const SizedBox(width: 12),
                Text(
                  '投资决策',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Decision metrics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: actionColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricColumn(
                    '建议操作',
                    widget.result.action.toUpperCase(),
                    actionColor,
                    icon: actionIcon,
                  ),
                  _buildVerticalDivider(),
                  _buildMetricColumn(
                    '置信度',
                    '${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                    _getConfidenceColor(widget.result.confidence),
                  ),
                  _buildVerticalDivider(),
                  _buildMetricColumn(
                    '建议数量',
                    '${widget.result.quantity}',
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentSignalsSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.users, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Agent信号汇总',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Agent signals grid
            ...widget.result.agentSignals.map((signal) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAgentSignalRow(signal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.brain, size: 20),
                const SizedBox(width: 8),
                Text(
                  '推理摘要',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                widget.result.reasoning,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for colors and icons
  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMetricColumn(String label, String value, Color color, {IconData? icon}) {
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildAgentSignalRow(AgentSignal signal) {
    final signalColor = _getSignalColor(signal.signal);
    final signalIcon = _getSignalIcon(signal.signal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: signalColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: signalColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(signalIcon, color: signalColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getAgentDisplayName(signal.agent),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            signal.signal.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: signalColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(signal.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor(String signal) {
    switch (signal.toLowerCase()) {
      case 'bullish':
        return Colors.green;
      case 'bearish':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSignalIcon(String signal) {
    switch (signal.toLowerCase()) {
      case 'bullish':
        return LucideIcons.trendingUp;
      case 'bearish':
        return LucideIcons.trendingDown;
      default:
        return LucideIcons.minus;
    }
  }

  String _getAgentDisplayName(String agent) {
    const agentNameMap = {
      'Technical Analysis': '技术分析',
      'Fundamental Analysis': '基本面分析',
      'Sentiment Analysis': '情绪分析',
      'Valuation Analysis': '估值分析',
      'Risk Management': '风险管理',
      'Macro Analysis': '宏观分析',
      'Portfolio Management': '投资组合管理',
    };
    return agentNameMap[agent] ?? agent;
  }

  // Build detailed agent analysis card
  Widget _buildAgentDetailCard(AgentDetailedAnalysis analysis) {
    // Use specialized widgets based on agent type
    if (analysis.technicalData != null) {
      return TechnicalAnalysisWidget(
        data: analysis.technicalData!,
        agentAnalysis: analysis,
      );
    } else if (analysis.fundamentalData != null) {
      return FundamentalAnalysisWidget(
        data: analysis.fundamentalData!,
        agentAnalysis: analysis,
      );
    } else if (analysis.sentimentData != null) {
      return _buildSentimentAnalysisCard(analysis);
    } else if (analysis.valuationData != null) {
      return _buildValuationAnalysisCard(analysis);
    } else if (analysis.riskData != null) {
      return _buildRiskAnalysisCard(analysis);
    } else if (analysis.macroData != null) {
      return _buildMacroAnalysisCard(analysis);
    } else {
      return _buildGenericAgentCard(analysis);
    }
  }

  Widget _buildSentimentAnalysisCard(AgentDetailedAnalysis analysis) {
    return Card(
      elevation: 2,
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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.heart,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '情绪分析',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '基于市场新闻和舆论的情绪分析',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analysis.sentimentData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSignalColor(analysis.sentimentData!.signal).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSignalColor(analysis.sentimentData!.signal).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '情绪信号',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          analysis.sentimentData!.signal.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getSignalColor(analysis.sentimentData!.signal),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('置信度', style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          analysis.sentimentData!.confidence,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (analysis.sentimentData!.sentimentScore != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('情绪分数', style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            analysis.sentimentData!.sentimentScore!.toStringAsFixed(2),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (analysis.sentimentData!.newsCount != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('新闻数量', style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            '${analysis.sentimentData!.newsCount}条',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValuationAnalysisCard(AgentDetailedAnalysis analysis) {
    return Card(
      elevation: 2,
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.calculator,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '估值分析',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analysis.valuationData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSignalColor(analysis.valuationData!.signal).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSignalColor(analysis.valuationData!.signal).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '估值信号: ${analysis.valuationData!.signal.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      analysis.valuationData!.confidence,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getSignalColor(analysis.valuationData!.signal),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysisCard(AgentDetailedAnalysis analysis) {
    return Card(
      elevation: 2,
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
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.shield,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '风险管理',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analysis.riskData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSignalColor(analysis.riskData!.signal).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSignalColor(analysis.riskData!.signal).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '风险信号: ${analysis.riskData!.signal.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      analysis.riskData!.confidence,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getSignalColor(analysis.riskData!.signal),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroAnalysisCard(AgentDetailedAnalysis analysis) {
    return Card(
      elevation: 2,
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
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.globe,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '宏观分析',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analysis.macroData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSignalColor(analysis.macroData!.signal).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSignalColor(analysis.macroData!.signal).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '宏观信号: ${analysis.macroData!.signal.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      analysis.macroData!.confidence,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getSignalColor(analysis.macroData!.signal),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenericAgentCard(AgentDetailedAnalysis analysis) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analysis.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '执行时间: ${analysis.executionTimeSeconds.toStringAsFixed(1)}秒',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '状态: ${analysis.status}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('工作流程摘要'),
      ),
    );
  }

  Widget _buildWorkflowTimeline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('工作流程时间线'),
      ),
    );
  }

  Widget _buildLLMInteractionCard(LLMInteraction interaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('LLM交互: ${interaction.agentName}'),
      ),
    );
  }
}
