import '../models/ai_analysis_result.dart';
import '../models/ai_config.dart';
import '../datasources/local/ai_suggestion_dao.dart';
import '../services/ai_service.dart';

class AISuggestionRepository {
  final AISuggestionDao _dao = AISuggestionDao();
  final AIService _aiService = AIService();

  // 获取股票分析
  Future<AIAnalysisResult> analyzeStock({
    required String stockCode,
    bool showReasoning = false,
    double initialCapital = 100000,
    int numOfNews = 5,
    String? startDate,
    String? endDate,
  }) async {
    return await _aiService.analyzeStock(
      stockCode: stockCode,
      showReasoning: showReasoning,
      initialCapital: initialCapital,
      numOfNews: numOfNews,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // 保存AI建议
  Future<String> saveSuggestion(AISuggestion suggestion) async {
    return await _dao.createSuggestion(suggestion);
  }

  // 获取用户的所有建议
  Future<List<AISuggestion>> getUserSuggestions(String userId) async {
    return await _dao.getSuggestionsByUser(userId);
  }

  // 获取待处理的建议
  Future<List<AISuggestion>> getPendingSuggestions(String userId) async {
    return await _dao.getPendingSuggestions(userId);
  }

  // 获取特定股票的建议
  Future<List<AISuggestion>> getStockSuggestions(String userId, String stockCode) async {
    return await _dao.getSuggestionsByStock(userId, stockCode);
  }

  // 获取建议详情
  Future<AISuggestion?> getSuggestionById(String id) async {
    return await _dao.getSuggestionById(id);
  }

  // 更新建议状态
  Future<void> updateSuggestion(AISuggestion suggestion) async {
    await _dao.updateSuggestion(suggestion);
  }

  // 标记建议为已执行
  Future<void> markAsExecuted(String suggestionId, String transactionId) async {
    final suggestion = await _dao.getSuggestionById(suggestionId);
    if (suggestion != null) {
      final updatedSuggestion = suggestion.copyWith(
        status: AISuggestionStatus.executed,
        executedAt: DateTime.now(),
        transactionId: transactionId,
      );
      await _dao.updateSuggestion(updatedSuggestion);
    }
  }

  // 标记建议为已忽略
  Future<void> markAsIgnored(String suggestionId, String? userNotes) async {
    final suggestion = await _dao.getSuggestionById(suggestionId);
    if (suggestion != null) {
      final updatedSuggestion = suggestion.copyWith(
        status: AISuggestionStatus.ignored,
        userNotes: userNotes,
      );
      await _dao.updateSuggestion(updatedSuggestion);
    }
  }

  // 删除建议
  Future<void> deleteSuggestion(String id) async {
    await _dao.deleteSuggestion(id);
  }

  // 检查AI服务是否可用
  Future<bool> isAIServiceAvailable() async {
    return await _aiService.isServiceAvailable();
  }

  // 获取工作流状态
  Future<Map<String, dynamic>> getWorkflowStatus() async {
    return await _aiService.getWorkflowStatus();
  }

  // 获取历史运行记录
  Future<List<Map<String, dynamic>>> getHistoryRuns() async {
    return await _aiService.getHistoryRuns();
  }

  // AI服务配置相关方法
  Future<String> getAIServiceUrl() async {
    return await _aiService.baseUrl;
  }

  Future<void> setAIServiceUrl(String url) async {
    await _aiService.setBaseUrl(url);
  }

  Future<void> resetAIServiceUrl() async {
    await _aiService.resetToDefault();
  }

  // API Key 配置方法
  Future<AIConfig> getAIConfig() async {
    return AIConfig(
      baseUrl: await _aiService.baseUrl,
      geminiApiKey: await _aiService.getGeminiApiKey(),
      geminiModel: await _aiService.getGeminiModel(),
      openaiApiKey: await _aiService.getOpenAIApiKey(),
      openaiBaseUrl: await _aiService.getOpenAIBaseUrl(),
      openaiModel: await _aiService.getOpenAIModel(),
    );
  }

  Future<void> updateAIConfig(AIConfig config) async {
    await _aiService.setBaseUrl(config.baseUrl);

    if (config.geminiApiKey != null) {
      await _aiService.setGeminiApiKey(config.geminiApiKey!);
    }
    await _aiService.setGeminiModel(config.geminiModel);

    if (config.openaiApiKey != null) {
      await _aiService.setOpenAIApiKey(config.openaiApiKey!);
    }
    if (config.openaiBaseUrl != null) {
      await _aiService.setOpenAIBaseUrl(config.openaiBaseUrl!);
    }
    await _aiService.setOpenAIModel(config.openaiModel);
  }

  Future<void> resetAIConfig() async {
    await _aiService.resetToDefault();
  }

  // 创建AI建议并保存到数据库
  Future<AISuggestion> createAndSaveSuggestion({
    required String userId,
    required AIAnalysisResult analysis,
  }) async {
    final suggestion = AISuggestion(
      userId: userId,
      analysis: analysis,
      createdAt: DateTime.now(),
    );

    final id = await _dao.createSuggestion(suggestion);
    return suggestion.copyWith(id: id);
  }
}
