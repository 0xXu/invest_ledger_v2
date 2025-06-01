import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_analysis_result.dart';
import 'stock_info_service.dart';

class AIService {
  static const String _defaultBaseUrl = 'http://localhost:8000';
  static const String _baseUrlKey = 'ai_service_base_url';
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _geminiModelKey = 'gemini_model';
  static const String _openaiApiKeyKey = 'openai_compatible_api_key';
  static const String _openaiBaseUrlKey = 'openai_compatible_base_url';
  static const String _openaiModelKey = 'openai_compatible_model';

  String? _cachedBaseUrl;

  Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    _cachedBaseUrl = url;
  }

  // API Key 配置方法
  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyKey);
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, apiKey);
  }

  Future<String> getGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiModelKey) ?? 'gemini-1.5-flash';
  }

  Future<void> setGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiModelKey, model);
  }

  Future<String?> getOpenAIApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openaiApiKeyKey);
  }

  Future<void> setOpenAIApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiApiKeyKey, apiKey);
  }

  Future<String?> getOpenAIBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openaiBaseUrlKey);
  }

  Future<void> setOpenAIBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiBaseUrlKey, baseUrl);
  }

  Future<String> getOpenAIModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openaiModelKey) ?? 'gpt-3.5-turbo';
  }

  Future<void> setOpenAIModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiModelKey, model);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKeyKey);
    await prefs.remove(_geminiModelKey);
    await prefs.remove(_openaiApiKeyKey);
    await prefs.remove(_openaiBaseUrlKey);
    await prefs.remove(_openaiModelKey);
    await setBaseUrl(_defaultBaseUrl);
  }

  // 分析股票
  Future<AIAnalysisResult> analyzeStock({
    required String stockCode,
    bool showReasoning = false,
    double initialCapital = 100000,
    int numOfNews = 5,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final url = await baseUrl;

      // 获取AI配置
      final aiConfig = await _buildAIConfig();

      // 构建请求体
      final requestBody = {
        'ticker': stockCode,
        'ai_config': aiConfig,
        'show_reasoning': showReasoning,
        'initial_capital': initialCapital,
        'num_of_news': numOfNews,
        'initial_position': 0,
      };

      // 添加可选的日期参数
      if (startDate != null && startDate.isNotEmpty) {
        requestBody['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        requestBody['end_date'] = endDate;
      }

      final response = await http.post(
        Uri.parse('$url/api/analysis/start'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final runId = data['data']['run_id'];

          // 轮询获取结果
          return await _pollForResult(runId, stockCode);
        } else {
          throw AIServiceException(data['message'] ?? '分析请求失败');
        }
      } else {
        throw AIServiceException('分析请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw AIServiceException('网络请求失败: $e');
    }
  }

  // 构建AI配置
  Future<Map<String, dynamic>> _buildAIConfig() async {
    // 检查Gemini配置
    final geminiApiKey = await getGeminiApiKey();
    final openaiApiKey = await getOpenAIApiKey();
    final openaiBaseUrl = await getOpenAIBaseUrl();

    // 优先使用有效的Gemini配置
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      return {
        'provider': 'gemini',
        'api_key': geminiApiKey,
        'model': await getGeminiModel(),
      };
    }

    // 如果没有Gemini配置，检查OpenAI配置
    if (openaiApiKey != null && openaiApiKey.isNotEmpty) {
      return {
        'provider': 'openai_compatible',
        'api_key': openaiApiKey,
        'model': await getOpenAIModel(),
        'base_url': openaiBaseUrl,
      };
    }

    throw AIServiceException('未配置AI服务API Key，请先在设置中配置');
  }

  // 轮询获取分析结果
  Future<AIAnalysisResult> _pollForResult(String runId, String stockCode) async {
    const maxAttempts = 60; // 最多等待5分钟
    const pollInterval = Duration(seconds: 5);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final url = await baseUrl;
        final response = await http.get(
          Uri.parse('$url/api/analysis/$runId/status'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final status = data['data']['status'];

            if (status == 'completed') {
              // 获取分析结果
              return await _getAnalysisResult(runId, stockCode);
            } else if (status == 'error') {
              throw AIServiceException('分析任务失败: ${data['data']['error'] ?? '未知错误'}');
            }
            // 如果状态是running，继续轮询
          }
        }

        await Future.delayed(pollInterval);
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          throw AIServiceException('获取分析结果超时: $e');
        }
      }
    }

    throw AIServiceException('分析任务超时');
  }

  // 获取分析结果
  Future<AIAnalysisResult> _getAnalysisResult(String runId, String stockCode) async {
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse('$url/api/analysis/$runId/result'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Get basic analysis result
        final basicResult = await _parseAnalysisResultAsync(stockCode, data['data']);

        // Fetch detailed analysis data
        try {
          final detailedAnalysis = await _getDetailedAnalysis(runId);
          final workflowFlow = await _getWorkflowFlow(runId);
          final llmInteractions = await _getLLMInteractions(runId);

          return basicResult.copyWith(
            runId: runId,
            detailedAnalysis: detailedAnalysis,
            workflowFlow: workflowFlow,
            llmInteractions: llmInteractions,
          );
        } catch (e) {
          // If detailed data fails, return basic result
          print('Warning: Failed to fetch detailed analysis data: $e');
          return basicResult.copyWith(runId: runId);
        }
      } else {
        throw AIServiceException(data['message'] ?? '获取分析结果失败');
      }
    } else {
      throw AIServiceException('获取分析结果失败: ${response.statusCode}');
    }
  }

  // 获取详细分析数据
  Future<Map<String, AgentDetailedAnalysis>> _getDetailedAnalysis(String runId) async {
    final url = await baseUrl;

    // First get the list of agents for this run
    final runResponse = await http.get(
      Uri.parse('$url/runs/$runId/agents'),
      headers: {'Content-Type': 'application/json'},
    );

    if (runResponse.statusCode != 200) {
      throw AIServiceException('获取运行代理列表失败: ${runResponse.statusCode}');
    }

    final agentSummaries = jsonDecode(runResponse.body) as List;
    final Map<String, AgentDetailedAnalysis> detailedAnalysis = {};

    // Fetch detailed data for each agent
    for (final agentSummary in agentSummaries) {
      final agentName = agentSummary['agent_name'] as String;

      try {
        final agentResponse = await http.get(
          Uri.parse('$url/runs/$runId/agents/$agentName'),
          headers: {'Content-Type': 'application/json'},
        );

        if (agentResponse.statusCode == 200) {
          final agentData = jsonDecode(agentResponse.body);
          final analysis = _parseAgentDetailedAnalysis(agentData);
          detailedAnalysis[agentName] = analysis;
        }
      } catch (e) {
        print('Warning: Failed to fetch detailed data for agent $agentName: $e');
      }
    }

    return detailedAnalysis;
  }

  // 获取工作流程图
  Future<WorkflowFlow?> _getWorkflowFlow(String runId) async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/runs/$runId/flow'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorkflowFlow.fromJson(data);
      }
    } catch (e) {
      print('Warning: Failed to fetch workflow flow: $e');
    }
    return null;
  }

  // 获取LLM交互记录
  Future<List<LLMInteraction>?> _getLLMInteractions(String runId) async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/logs/?run_id=$runId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => LLMInteraction.fromJson(item)).toList();
      }
    } catch (e) {
      print('Warning: Failed to fetch LLM interactions: $e');
    }
    return null;
  }

  // 获取工作流状态
  Future<Map<String, dynamic>> getWorkflowStatus() async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/api/workflow/status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw AIServiceException('获取状态失败: ${response.statusCode}');
      }
    } catch (e) {
      throw AIServiceException('网络请求失败: $e');
    }
  }

  // 获取历史运行记录
  Future<List<Map<String, dynamic>>> getHistoryRuns() async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/runs/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw AIServiceException('获取历史记录失败: ${response.statusCode}');
      }
    } catch (e) {
      throw AIServiceException('网络请求失败: $e');
    }
  }

  // 开始回测
  Future<BacktestResult> startBacktest({
    required String stockCode,
    required String startDate,
    required String endDate,
    double initialCapital = 100000,
    int numOfNews = 5,
  }) async {
    try {
      final url = await baseUrl;
      print('🌐 使用API地址: $url');

      // 获取AI配置
      print('🔧 正在获取AI配置...');
      final aiConfig = await _buildAIConfig();
      print('✅ AI配置获取成功: ${aiConfig['provider']}');

      // 构建请求体
      final requestBody = {
        'ticker': stockCode,
        'ai_config': aiConfig,
        'start_date': startDate,
        'end_date': endDate,
        'initial_capital': initialCapital,
        'num_of_news': numOfNews,
      };
      print('📦 请求体: ${jsonEncode(requestBody)}');

      print('🚀 发送回测请求到: $url/api/analysis/backtest/start');
      final response = await http.post(
        Uri.parse('$url/api/analysis/backtest/start'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 收到响应: ${response.statusCode}');
      print('📄 响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final runId = data['data']['run_id'];

          // 轮询获取回测结果
          return await _pollForBacktestResult(runId, stockCode);
        } else {
          throw AIServiceException(data['message'] ?? '回测请求失败');
        }
      } else {
        throw AIServiceException('回测请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw AIServiceException('网络请求失败: $e');
    }
  }

  // 轮询获取回测结果
  Future<BacktestResult> _pollForBacktestResult(String runId, String stockCode) async {
    const maxAttempts = 120; // 最多等待10分钟
    const pollInterval = Duration(seconds: 5);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final url = await baseUrl;
        final response = await http.get(
          Uri.parse('$url/api/runs/$runId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final status = data['data']['status'];

            if (status == 'completed') {
              // 获取回测结果
              return await _getBacktestResult(runId, stockCode);
            } else if (status == 'error') {
              throw AIServiceException('回测任务失败: ${data['data']['error'] ?? '未知错误'}');
            }
            // 如果状态是running，继续轮询
          }
        }

        await Future.delayed(pollInterval);
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          throw AIServiceException('获取回测结果超时: $e');
        }
      }
    }

    throw AIServiceException('回测任务超时');
  }

  // 获取回测结果
  Future<BacktestResult> _getBacktestResult(String runId, String stockCode) async {
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse('$url/api/analysis/backtest/$runId/result'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final resultData = data['data'];

        // 解析时间序列数据
        List<BacktestDataPoint> timeSeriesData = [];
        if (resultData['time_series_data'] != null) {
          timeSeriesData = (resultData['time_series_data'] as List)
              .map((point) => BacktestDataPoint(
                    date: point['date'],
                    portfolioValue: (point['portfolio_value'] as num).toDouble(),
                    cumulativeReturn: (point['cumulative_return'] as num).toDouble(),
                    dailyReturn: (point['daily_return'] as num).toDouble(),
                  ))
              .toList();
        }

        // 安全地转换性能指标
        Map<String, double> performanceMetrics = {};
        if (resultData['performance_metrics'] != null) {
          final metrics = resultData['performance_metrics'] as Map<String, dynamic>;
          metrics.forEach((key, value) {
            if (value is num) {
              performanceMetrics[key] = value.toDouble();
            } else if (value is String) {
              performanceMetrics[key] = double.tryParse(value) ?? 0.0;
            } else {
              performanceMetrics[key] = 0.0;
            }
          });
        }

        return BacktestResult(
          runId: runId,
          stockCode: stockCode,
          timeSeriesData: timeSeriesData,
          performanceMetrics: performanceMetrics,
          status: resultData['status'] ?? 'completed',
          message: resultData['message'] ?? '回测完成',
          completedAt: resultData['completed_at'] != null
            ? DateTime.parse(resultData['completed_at'])
            : DateTime.now(),
        );
      } else {
        throw AIServiceException(data['message'] ?? '获取回测结果失败');
      }
    } else {
      throw AIServiceException('获取回测结果失败: ${response.statusCode}');
    }
  }

  // 解析AI分析结果
  Future<AIAnalysisResult> _parseAnalysisResultAsync(String stockCode, Map<String, dynamic> data) async {
    // 从API响应中提取股票名称
    String stockName = stockCode; // 默认使用股票代码

    // 尝试从不同位置获取股票名称
    if (data.containsKey('stock_name')) {
      stockName = data['stock_name']?.toString() ?? stockCode;
    } else if (data.containsKey('stockName')) {
      stockName = data['stockName']?.toString() ?? stockCode;
    } else if (data.containsKey('name')) {
      stockName = data['name']?.toString() ?? stockCode;
    } else {
      // 如果没有找到股票名称，尝试从ticker字段获取
      String ticker = data['ticker']?.toString() ?? stockCode;
      if (ticker != stockCode) {
        stockName = ticker;
      } else {
        // 最后尝试从股票信息服务获取
        try {
          stockName = await StockInfoService.getStockName(stockCode);
        } catch (e) {
          // 如果获取失败，保持使用股票代码
          stockName = stockCode;
        }
      }
    }

    // 解析最终决策 - 这是portfolio_management返回的主要决策数据
    Map<String, dynamic>? finalDecision = data['final_decision'];
    String action = 'HOLD';
    int quantity = 0;
    double confidence = 0.0;
    String reasoning = '';
    List<AgentSignal> agentSignals = [];

    if (finalDecision != null) {
      // 从final_decision中提取基本信息
      action = finalDecision['action']?.toString().toUpperCase() ?? 'HOLD';

      // 安全地转换quantity
      var quantityValue = finalDecision['quantity'];
      if (quantityValue is int) {
        quantity = quantityValue;
      } else if (quantityValue is double) {
        quantity = quantityValue.toInt();
      } else if (quantityValue is String) {
        quantity = int.tryParse(quantityValue) ?? 0;
      } else {
        quantity = 0;
      }

      // 安全地转换confidence
      var confidenceValue = finalDecision['confidence'];
      if (confidenceValue is double) {
        confidence = confidenceValue;
      } else if (confidenceValue is int) {
        confidence = confidenceValue.toDouble();
      } else if (confidenceValue is String) {
        confidence = double.tryParse(confidenceValue) ?? 0.0;
      } else {
        confidence = 0.0;
      }

      reasoning = finalDecision['reasoning']?.toString() ?? '';

      // 解析agent_signals - 这是portfolio_management整理的各Agent信号
      if (finalDecision['agent_signals'] is List) {
        final signals = finalDecision['agent_signals'] as List;
        for (final signalData in signals) {
          if (signalData is Map<String, dynamic>) {
            try {
              // 注意：后端使用的是 agent_name，前端期望的是 agent
              String rawAgentName = signalData['agent_name']?.toString() ??
                                   signalData['agent']?.toString() ??
                                   'unknown';

              // 映射Agent名称为友好的中文名称
              String agentName = _mapAgentName(rawAgentName);
              String signal = signalData['signal']?.toString().toLowerCase() ?? 'neutral';

              // 解析置信度
              double agentConfidence = 0.0;
              var confValue = signalData['confidence'];
              if (confValue is double) {
                agentConfidence = confValue;
              } else if (confValue is int) {
                agentConfidence = confValue.toDouble();
              } else if (confValue is String) {
                agentConfidence = double.tryParse(confValue) ?? 0.0;
              }

              String agentReasoning = signalData['reasoning']?.toString() ?? '';

              agentSignals.add(AgentSignal(
                agent: agentName,
                signal: signal,
                confidence: agentConfidence,
                reasoning: agentReasoning,
              ));
            } catch (e) {
              // 添加错误信号
              agentSignals.add(AgentSignal(
                agent: 'unknown',
                signal: 'neutral',
                confidence: 0.0,
                reasoning: '解析Agent信号时出错: $e',
              ));
            }
          }
        }
      }
    }

    // 如果final_decision中没有agent_signals，尝试从agent_results解析
    if (agentSignals.isEmpty) {
      Map<String, dynamic>? agentResults = data['agent_results'];
      if (agentResults != null) {
        agentResults.forEach((agentName, agentData) {
          try {
            final parsedSignal = _parseAgentData(agentName, agentData);
            if (parsedSignal != null) {
              agentSignals.add(parsedSignal);
            }
          } catch (e) {
            agentSignals.add(AgentSignal(
              agent: agentName,
              signal: 'neutral',
              confidence: 0.0,
              reasoning: '解析数据时出错: $e',
            ));
          }
        });
      }
    }

    return AIAnalysisResult(
      stockCode: stockCode,
      stockName: stockName,
      action: action,
      quantity: quantity,
      confidence: confidence,
      agentSignals: agentSignals,
      reasoning: reasoning,
      analysisTime: DateTime.now(),
    );
  }

  // 解析Agent详细分析数据
  AgentDetailedAnalysis _parseAgentDetailedAnalysis(Map<String, dynamic> data) {
    final agentName = data['agent_name'] as String;
    final displayName = _mapAgentName(agentName);

    return AgentDetailedAnalysis(
      agentName: agentName,
      displayName: displayName,
      startTime: DateTime.parse(data['start_time']),
      endTime: DateTime.parse(data['end_time']),
      executionTimeSeconds: (data['execution_time_seconds'] as num).toDouble(),
      status: data['status'] as String,
      inputState: data['input_state'] as Map<String, dynamic>?,
      outputState: data['output_state'] as Map<String, dynamic>?,
      reasoning: data['reasoning'] as Map<String, dynamic>?,
      llmInteractionIds: (data['llm_interactions'] as List?)?.cast<String>(),
      // Parse agent-specific data based on agent type
      technicalData: _parseTechnicalData(agentName, data),
      fundamentalData: _parseFundamentalData(agentName, data),
      sentimentData: _parseSentimentData(agentName, data),
      valuationData: _parseValuationData(agentName, data),
      riskData: _parseRiskData(agentName, data),
      macroData: _parseMacroData(agentName, data),
    );
  }

  // 解析技术分析数据
  TechnicalAnalysisData? _parseTechnicalData(String agentName, Map<String, dynamic> data) {
    if (!agentName.contains('technical')) return null;

    final reasoning = data['reasoning'] as Map<String, dynamic>?;
    if (reasoning == null) return null;

    return TechnicalAnalysisData(
      signal: reasoning['signal'] as String? ?? 'neutral',
      confidence: reasoning['confidence'] as String? ?? '0%',
      strategySignals: _parseStrategySignals(reasoning['strategy_signals']),
      indicators: reasoning['indicators'] as Map<String, dynamic>?,
      patterns: reasoning['patterns'] as Map<String, dynamic>?,
    );
  }

  // 解析策略信号
  Map<String, StrategySignal>? _parseStrategySignals(dynamic strategyData) {
    if (strategyData == null) return null;

    final Map<String, StrategySignal> signals = {};
    final strategyMap = strategyData as Map<String, dynamic>;

    for (final entry in strategyMap.entries) {
      final signalData = entry.value as Map<String, dynamic>;
      signals[entry.key] = StrategySignal(
        signal: signalData['signal'] as String? ?? 'neutral',
        confidence: signalData['confidence'] as String? ?? '0%',
        metrics: signalData['metrics'] as Map<String, dynamic>?,
      );
    }

    return signals;
  }

  // 解析基本面分析数据
  FundamentalAnalysisData? _parseFundamentalData(String agentName, Map<String, dynamic> data) {
    if (!agentName.contains('fundamental')) return null;

    final reasoning = data['reasoning'] as Map<String, dynamic>?;
    if (reasoning == null) return null;

    return FundamentalAnalysisData(
      signal: reasoning['signal'] as String? ?? 'neutral',
      confidence: reasoning['confidence'] as String? ?? '0%',
      reasoning: reasoning['reasoning'] as Map<String, dynamic>?,
      metrics: reasoning['metrics'] as Map<String, dynamic>?,
      ratios: reasoning['ratios'] as Map<String, dynamic>?,
    );
  }

  // 解析情绪分析数据
  SentimentAnalysisData? _parseSentimentData(String agentName, Map<String, dynamic> data) {
    if (!agentName.contains('sentiment')) return null;

    final reasoning = data['reasoning'] as Map<String, dynamic>?;
    if (reasoning == null) return null;

    return SentimentAnalysisData(
      signal: reasoning['signal'] as String? ?? 'neutral',
      confidence: reasoning['confidence'] as String? ?? '0%',
      reasoning: reasoning['reasoning'] as String?,
      sentimentScore: reasoning['sentiment_score'] as double?,
      newsCount: reasoning['news_count'] as int?,
      newsItems: _parseNewsItems(reasoning['news_items']),
    );
  }

  // 解析新闻项目
  List<NewsItem>? _parseNewsItems(dynamic newsData) {
    if (newsData == null) return null;

    final newsList = newsData as List;
    return newsList.map((item) {
      final newsMap = item as Map<String, dynamic>;
      return NewsItem(
        title: newsMap['title'] as String,
        content: newsMap['content'] as String,
        publishTime: DateTime.parse(newsMap['publish_time']),
        sentimentScore: newsMap['sentiment_score'] as double?,
        source: newsMap['source'] as String?,
      );
    }).toList();
  }

  // 解析估值分析数据
  ValuationAnalysisData? _parseValuationData(String agentName, Map<String, dynamic> data) {
    if (!agentName.contains('valuation')) return null;

    final reasoning = data['reasoning'] as Map<String, dynamic>?;
    if (reasoning == null) return null;

    return ValuationAnalysisData(
      signal: reasoning['signal'] as String? ?? 'neutral',
      confidence: reasoning['confidence'] as String? ?? '0%',
      reasoning: reasoning['reasoning'] as Map<String, dynamic>?,
      valuationMetrics: reasoning['valuation_metrics'] as Map<String, dynamic>?,
      comparisons: reasoning['comparisons'] as Map<String, dynamic>?,
    );
  }

  // 解析风险分析数据
  RiskAnalysisData? _parseRiskData(String agentName, Map<String, dynamic> data) {
    if (!agentName.contains('risk')) return null;

    final reasoning = data['reasoning'] as Map<String, dynamic>?;
    if (reasoning == null) return null;

    return RiskAnalysisData(
      signal: reasoning['signal'] as String? ?? 'neutral',
      confidence: reasoning['confidence'] as String? ?? '0%',
      riskMetrics: reasoning['risk_metrics'] as Map<String, dynamic>?,
      constraints: reasoning['constraints'] as Map<String, dynamic>?,
      maxPositionSize: reasoning['max_position_size'] as double?,
      riskScore: reasoning['risk_score'] as double?,
    );
  }

  // 解析宏观分析数据
  MacroAnalysisData? _parseMacroData(String agentName, Map<String, dynamic> data) {
    if (!agentName.contains('macro')) return null;

    final reasoning = data['reasoning'] as Map<String, dynamic>?;
    if (reasoning == null) return null;

    return MacroAnalysisData(
      signal: reasoning['signal'] as String? ?? 'neutral',
      confidence: reasoning['confidence'] as String? ?? '0%',
      reasoning: reasoning['reasoning'] as String?,
      macroIndicators: reasoning['macro_indicators'] as Map<String, dynamic>?,
      marketConditions: reasoning['market_conditions'] as Map<String, dynamic>?,
    );
  }

  // 映射Agent名称为友好的中文名称
  String _mapAgentName(String rawAgentName) {
    const agentNameMap = {
      'technical_analysis': '技术分析',
      'technical_analyst': '技术分析',
      'fundamental_analysis': '基本面分析',
      'fundamentals': '基本面分析',
      'sentiment_analysis': '情感分析',
      'sentiment': '情感分析',
      'valuation_analysis': '估值分析',
      'valuation': '估值分析',
      'risk_management': '风险管理',
      'risk_manager': '风险管理',
      'selected_stock_macro_analysis': '宏观分析',
      'macro_analyst_agent': '宏观分析',
      'macro_analyst': '宏观分析',
      'market_wide_news_summary(沪深300指数)': '大盘新闻分析',
      'macro_news_agent': '大盘新闻分析',
      'portfolio_management': '投资组合管理',
      'portfolio_management_agent': '投资组合管理',
      'market_data': '市场数据',
      'market_data_agent': '市场数据',
      'debate_room': '辩论室',
      'debate_room_agent': '辩论室',
      'researcher_bull': '多头研究员',
      'researcher_bear': '空头研究员',
      'bullish_researcher': '多头研究员',
      'bearish_researcher': '空头研究员',
    };

    return agentNameMap[rawAgentName] ?? rawAgentName;
  }

  // 解析单个Agent的数据
  AgentSignal? _parseAgentData(String agentName, dynamic agentData) {
    if (agentData == null) return null;

    // 映射Agent名称为友好的中文名称
    String friendlyAgentName = _mapAgentName(agentName);

    // 后端已经通过safe_parse_json和serialize_for_api处理过数据
    // 所以agentData应该已经是解析后的Map或其他结构
    Map<String, dynamic> parsedData;

    if (agentData is Map<String, dynamic>) {
      parsedData = agentData;
    } else if (agentData is String) {
      // 如果仍然是字符串，尝试再次解析
      try {
        parsedData = jsonDecode(agentData);
      } catch (e) {
        // 如果不是JSON，将字符串作为reasoning
        return AgentSignal(
          agent: friendlyAgentName,
          signal: 'neutral',
          confidence: 0.0,
          reasoning: agentData,
        );
      }
    } else {
      // 其他类型，尝试转换为字符串作为reasoning
      return AgentSignal(
        agent: friendlyAgentName,
        signal: 'neutral',
        confidence: 0.0,
        reasoning: agentData.toString(),
      );
    }

    // 提取信号信息
    String signal = 'neutral';
    double confidence = 0.0;
    String reasoning = '';

    // 根据不同的Agent类型解析数据
    switch (agentName) {
      case 'fundamentals':
      case 'fundamental_analysis':
        signal = _extractSignalFromFundamentals(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromFundamentals(parsedData);
        break;

      case 'sentiment':
      case 'sentiment_analysis':
        signal = _extractSignalFromSentiment(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromSentiment(parsedData);
        break;

      case 'valuation':
      case 'valuation_analysis':
        signal = _extractSignalFromValuation(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromValuation(parsedData);
        break;

      case 'debate_room':
        signal = _extractSignalFromDebate(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromDebate(parsedData);
        break;

      case 'macro_analyst':
      case 'selected_stock_macro_analysis':
        signal = _extractSignalFromMacro(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromMacro(parsedData);
        break;

      case 'researcher_bull':
      case 'researcher_bear':
        signal = _extractSignalFromResearcher(parsedData, agentName);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromResearcher(parsedData);
        break;

      case 'portfolio_management':
        signal = _extractSignalFromPortfolio(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractReasoningFromPortfolio(parsedData);
        break;

      default:
        // 通用解析逻辑
        signal = _extractGenericSignal(parsedData);
        confidence = _extractConfidenceFromData(parsedData);
        reasoning = _extractGenericReasoning(parsedData);
    }

    return AgentSignal(
      agent: friendlyAgentName,
      signal: signal,
      confidence: confidence,
      reasoning: reasoning,
    );
  }

  // 通用信号提取
  String _extractGenericSignal(Map<String, dynamic> data) {
    if (data.containsKey('signal')) {
      return data['signal']?.toString().toLowerCase() ?? 'neutral';
    }
    if (data.containsKey('recommendation')) {
      return data['recommendation']?.toString().toLowerCase() ?? 'neutral';
    }
    if (data.containsKey('action')) {
      return data['action']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  // 通用置信度提取
  double _extractConfidenceFromData(Map<String, dynamic> data) {
    if (data.containsKey('confidence')) {
      final confValue = data['confidence'];
      if (confValue is double) return confValue;
      if (confValue is int) return confValue.toDouble();
      if (confValue is String) {
        // 处理百分比字符串，如 "75%"
        String cleanValue = confValue.replaceAll('%', '');
        double? parsed = double.tryParse(cleanValue);
        if (parsed != null) {
          // 如果是百分比形式，转换为小数
          return parsed > 1 ? parsed / 100 : parsed;
        }
      }
    }
    return 0.0;
  }

  // 通用推理提取
  String _extractGenericReasoning(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      return data['reasoning']?.toString() ?? '';
    }
    if (data.containsKey('analysis')) {
      return data['analysis']?.toString() ?? '';
    }
    return jsonEncode(data); // 如果没有特定字段，返回整个数据的JSON
  }

  // 基本面分析信号提取
  String _extractSignalFromFundamentals(Map<String, dynamic> data) {
    if (data.containsKey('signal')) {
      return data['signal']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  String _extractReasoningFromFundamentals(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      final reasoning = data['reasoning'];
      if (reasoning is Map) {
        // 组合各个分析部分，基于实际的fundamentals agent结构
        List<String> parts = [];
        reasoning.forEach((key, value) {
          if (value is Map && value.containsKey('details')) {
            String signal = value['signal'] ?? '';
            String details = value['details'] ?? '';
            parts.add('$key ($signal): $details');
          }
        });
        return parts.isNotEmpty ? parts.join('\n') : reasoning.toString();
      }
      return reasoning?.toString() ?? '';
    }
    return _extractGenericReasoning(data);
  }

  // 情感分析信号提取
  String _extractSignalFromSentiment(Map<String, dynamic> data) {
    if (data.containsKey('signal')) {
      return data['signal']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  String _extractReasoningFromSentiment(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      return data['reasoning']?.toString() ?? '';
    }
    return _extractGenericReasoning(data);
  }

  // 估值分析信号提取
  String _extractSignalFromValuation(Map<String, dynamic> data) {
    if (data.containsKey('signal')) {
      return data['signal']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  String _extractReasoningFromValuation(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      final reasoning = data['reasoning'];
      if (reasoning is Map) {
        List<String> parts = [];
        reasoning.forEach((key, value) {
          if (value is Map && value.containsKey('details')) {
            String signal = value['signal'] ?? '';
            String details = value['details'] ?? '';
            parts.add('$key ($signal): $details');
          }
        });
        return parts.isNotEmpty ? parts.join('\n') : reasoning.toString();
      }
      return reasoning?.toString() ?? '';
    }
    return _extractGenericReasoning(data);
  }

  // 辩论室分析信号提取
  String _extractSignalFromDebate(Map<String, dynamic> data) {
    if (data.containsKey('signal')) {
      return data['signal']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  String _extractReasoningFromDebate(Map<String, dynamic> data) {
    List<String> parts = [];

    // 添加LLM分析
    if (data.containsKey('llm_analysis') && data['llm_analysis'] != null) {
      parts.add('LLM分析: ${data['llm_analysis']}');
    }

    // 添加LLM推理
    if (data.containsKey('llm_reasoning') && data['llm_reasoning'] != null) {
      parts.add('LLM推理: ${data['llm_reasoning']}');
    }

    // 添加辩论总结
    if (data.containsKey('debate_summary')) {
      final summary = data['debate_summary'];
      if (summary is List) {
        parts.add('辩论总结:\n${summary.join('\n')}');
      } else if (summary != null) {
        parts.add('辩论总结: $summary');
      }
    }

    // 添加置信度信息
    if (data.containsKey('bull_confidence') && data.containsKey('bear_confidence')) {
      parts.add('多方置信度: ${data['bull_confidence']}, 空方置信度: ${data['bear_confidence']}');
    }

    return parts.isNotEmpty ? parts.join('\n\n') : _extractGenericReasoning(data);
  }

  // 宏观分析信号提取
  String _extractSignalFromMacro(Map<String, dynamic> data) {
    if (data.containsKey('impact_on_stock')) {
      return data['impact_on_stock']?.toString().toLowerCase() ?? 'neutral';
    }
    if (data.containsKey('macro_environment')) {
      return data['macro_environment']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  String _extractReasoningFromMacro(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      return data['reasoning']?.toString() ?? '';
    }
    return _extractGenericReasoning(data);
  }

  // 研究员分析信号提取
  String _extractSignalFromResearcher(Map<String, dynamic> data, String agentName) {
    if (data.containsKey('perspective')) {
      return data['perspective']?.toString().toLowerCase() ?? 'neutral';
    }
    // 根据研究员类型推断
    if (agentName.contains('bull')) return 'bullish';
    if (agentName.contains('bear')) return 'bearish';
    return 'neutral';
  }

  String _extractReasoningFromResearcher(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      return data['reasoning']?.toString() ?? '';
    }
    if (data.containsKey('thesis_points')) {
      final points = data['thesis_points'];
      if (points is List) {
        return points.join(', ');
      }
    }
    return _extractGenericReasoning(data);
  }

  // 投资组合管理信号提取
  String _extractSignalFromPortfolio(Map<String, dynamic> data) {
    if (data.containsKey('trading_action')) {
      return data['trading_action']?.toString().toLowerCase() ?? 'neutral';
    }
    if (data.containsKey('action')) {
      return data['action']?.toString().toLowerCase() ?? 'neutral';
    }
    return 'neutral';
  }

  String _extractReasoningFromPortfolio(Map<String, dynamic> data) {
    if (data.containsKey('reasoning')) {
      return data['reasoning']?.toString() ?? '';
    }
    return _extractGenericReasoning(data);
  }

  // 检查AI服务是否可用
  Future<bool> isServiceAvailable() async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
