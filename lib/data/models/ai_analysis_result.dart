import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'ai_analysis_result.freezed.dart';
part 'ai_analysis_result.g.dart';

@freezed
class AIAnalysisResult with _$AIAnalysisResult {
  const factory AIAnalysisResult({
    required String stockCode,
    required String stockName,
    required String action, // "buy", "sell", "hold"
    required int quantity,
    required double confidence,
    required List<AgentSignal> agentSignals,
    required String reasoning,
    required DateTime analysisTime,
    Decimal? currentPrice,
    Decimal? suggestedPrice,
    // Enhanced detailed analysis data
    String? runId,
    Map<String, AgentDetailedAnalysis>? detailedAnalysis,
    WorkflowFlow? workflowFlow,
    List<LLMInteraction>? llmInteractions,
  }) = _AIAnalysisResult;

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AIAnalysisResultFromJson(json);
}

@freezed
class AgentSignal with _$AgentSignal {
  const factory AgentSignal({
    required String agent,
    required String signal, // "bullish", "bearish", "neutral"
    required double confidence,
    String? reasoning,
  }) = _AgentSignal;

  factory AgentSignal.fromJson(Map<String, dynamic> json) =>
      _$AgentSignalFromJson(json);
}

// Enhanced detailed analysis models
@freezed
class AgentDetailedAnalysis with _$AgentDetailedAnalysis {
  const factory AgentDetailedAnalysis({
    required String agentName,
    required String displayName,
    required DateTime startTime,
    required DateTime endTime,
    required double executionTimeSeconds,
    required String status,
    Map<String, dynamic>? inputState,
    Map<String, dynamic>? outputState,
    Map<String, dynamic>? reasoning,
    List<String>? llmInteractionIds,
    // Agent-specific analysis data
    TechnicalAnalysisData? technicalData,
    FundamentalAnalysisData? fundamentalData,
    SentimentAnalysisData? sentimentData,
    ValuationAnalysisData? valuationData,
    RiskAnalysisData? riskData,
    MacroAnalysisData? macroData,
  }) = _AgentDetailedAnalysis;

  factory AgentDetailedAnalysis.fromJson(Map<String, dynamic> json) =>
      _$AgentDetailedAnalysisFromJson(json);
}

@freezed
class TechnicalAnalysisData with _$TechnicalAnalysisData {
  const factory TechnicalAnalysisData({
    required String signal,
    required String confidence,
    Map<String, StrategySignal>? strategySignals,
    Map<String, dynamic>? indicators,
    Map<String, dynamic>? patterns,
  }) = _TechnicalAnalysisData;

  factory TechnicalAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$TechnicalAnalysisDataFromJson(json);
}

@freezed
class StrategySignal with _$StrategySignal {
  const factory StrategySignal({
    required String signal,
    required String confidence,
    Map<String, dynamic>? metrics,
  }) = _StrategySignal;

  factory StrategySignal.fromJson(Map<String, dynamic> json) =>
      _$StrategySignalFromJson(json);
}

@freezed
class FundamentalAnalysisData with _$FundamentalAnalysisData {
  const factory FundamentalAnalysisData({
    required String signal,
    required String confidence,
    Map<String, dynamic>? reasoning,
    Map<String, dynamic>? metrics,
    Map<String, dynamic>? ratios,
  }) = _FundamentalAnalysisData;

  factory FundamentalAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$FundamentalAnalysisDataFromJson(json);
}

@freezed
class SentimentAnalysisData with _$SentimentAnalysisData {
  const factory SentimentAnalysisData({
    required String signal,
    required String confidence,
    String? reasoning,
    double? sentimentScore,
    int? newsCount,
    List<NewsItem>? newsItems,
  }) = _SentimentAnalysisData;

  factory SentimentAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$SentimentAnalysisDataFromJson(json);
}

@freezed
class NewsItem with _$NewsItem {
  const factory NewsItem({
    required String title,
    required String content,
    required DateTime publishTime,
    double? sentimentScore,
    String? source,
  }) = _NewsItem;

  factory NewsItem.fromJson(Map<String, dynamic> json) =>
      _$NewsItemFromJson(json);
}

@freezed
class ValuationAnalysisData with _$ValuationAnalysisData {
  const factory ValuationAnalysisData({
    required String signal,
    required String confidence,
    Map<String, dynamic>? reasoning,
    Map<String, dynamic>? valuationMetrics,
    Map<String, dynamic>? comparisons,
  }) = _ValuationAnalysisData;

  factory ValuationAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$ValuationAnalysisDataFromJson(json);
}

@freezed
class RiskAnalysisData with _$RiskAnalysisData {
  const factory RiskAnalysisData({
    required String signal,
    required String confidence,
    Map<String, dynamic>? riskMetrics,
    Map<String, dynamic>? constraints,
    double? maxPositionSize,
    double? riskScore,
  }) = _RiskAnalysisData;

  factory RiskAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$RiskAnalysisDataFromJson(json);
}

@freezed
class MacroAnalysisData with _$MacroAnalysisData {
  const factory MacroAnalysisData({
    required String signal,
    required String confidence,
    String? reasoning,
    Map<String, dynamic>? macroIndicators,
    Map<String, dynamic>? marketConditions,
  }) = _MacroAnalysisData;

  factory MacroAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$MacroAnalysisDataFromJson(json);
}

@freezed
class WorkflowFlow with _$WorkflowFlow {
  const factory WorkflowFlow({
    required String runId,
    required DateTime startTime,
    required DateTime endTime,
    required Map<String, AgentSummary> agents,
    required List<StateTransition> stateTransitions,
    Map<String, dynamic>? finalDecision,
  }) = _WorkflowFlow;

  factory WorkflowFlow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFlowFromJson(json);
}

@freezed
class AgentSummary with _$AgentSummary {
  const factory AgentSummary({
    required String agentName,
    required DateTime startTime,
    required DateTime endTime,
    required double executionTimeSeconds,
    required String status,
  }) = _AgentSummary;

  factory AgentSummary.fromJson(Map<String, dynamic> json) =>
      _$AgentSummaryFromJson(json);
}

@freezed
class StateTransition with _$StateTransition {
  const factory StateTransition({
    required String fromAgent,
    required String toAgent,
    required int stateSize,
    required DateTime timestamp,
  }) = _StateTransition;

  factory StateTransition.fromJson(Map<String, dynamic> json) =>
      _$StateTransitionFromJson(json);
}

@freezed
class LLMInteraction with _$LLMInteraction {
  const factory LLMInteraction({
    required String agentName,
    required String runId,
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> responseData,
    required DateTime timestamp,
  }) = _LLMInteraction;

  factory LLMInteraction.fromJson(Map<String, dynamic> json) =>
      _$LLMInteractionFromJson(json);
}

@freezed
class AISuggestion with _$AISuggestion {
  const factory AISuggestion({
    String? id,
    required String userId,
    required AIAnalysisResult analysis,
    required DateTime createdAt,
    DateTime? executedAt,
    String? transactionId, // 如果用户执行了建议，关联的交易ID
    @Default(AISuggestionStatus.pending) AISuggestionStatus status,
    String? userNotes,
  }) = _AISuggestion;

  factory AISuggestion.fromJson(Map<String, dynamic> json) =>
      _$AISuggestionFromJson(json);
}

enum AISuggestionStatus {
  pending,    // 待处理
  executed,   // 已执行
  ignored,    // 已忽略
  expired,    // 已过期
}

@freezed
class BacktestDataPoint with _$BacktestDataPoint {
  const factory BacktestDataPoint({
    required String date,
    required double portfolioValue,
    required double cumulativeReturn,
    required double dailyReturn,
  }) = _BacktestDataPoint;

  factory BacktestDataPoint.fromJson(Map<String, dynamic> json) =>
      _$BacktestDataPointFromJson(json);
}

@freezed
class BacktestResult with _$BacktestResult {
  const factory BacktestResult({
    required String runId,
    required String stockCode,
    @Default([]) List<BacktestDataPoint> timeSeriesData,
    @Default({}) Map<String, double> performanceMetrics,
    @Default('completed') String status,
    @Default('回测完成') String message,
    required DateTime completedAt,
  }) = _BacktestResult;

  factory BacktestResult.fromJson(Map<String, dynamic> json) =>
      _$BacktestResultFromJson(json);
}
