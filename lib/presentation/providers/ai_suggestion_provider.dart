import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_analysis_result.dart';
import '../../data/repositories/ai_suggestion_repository.dart';
import 'user_provider.dart';

// AI建议仓库提供者
final aiSuggestionRepositoryProvider = Provider<AISuggestionRepository>((ref) {
  return AISuggestionRepository();
});

// AI服务状态提供者
final aiServiceStatusProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(aiSuggestionRepositoryProvider);
  return await repository.isAIServiceAvailable();
});

// 用户AI建议列表提供者
final userAISuggestionsProvider = FutureProvider<List<AISuggestion>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final repository = ref.read(aiSuggestionRepositoryProvider);
  return await repository.getUserSuggestions(user.id);
});

// 待处理AI建议提供者
final pendingAISuggestionsProvider = FutureProvider<List<AISuggestion>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final repository = ref.read(aiSuggestionRepositoryProvider);
  return await repository.getPendingSuggestions(user.id);
});

// 股票分析状态提供者
class StockAnalysisNotifier extends StateNotifier<AsyncValue<AIAnalysisResult?>> {
  StockAnalysisNotifier(this._repository) : super(const AsyncValue.data(null));

  final AISuggestionRepository _repository;

  Future<void> analyzeStock({
    required String stockCode,
    bool showReasoning = false,
    double initialCapital = 100000,
    int numOfNews = 5,
    String? startDate,
    String? endDate,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.analyzeStock(
        stockCode: stockCode,
        showReasoning: showReasoning,
        initialCapital: initialCapital,
        numOfNews: numOfNews,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearAnalysis() {
    state = const AsyncValue.data(null);
  }
}

final stockAnalysisProvider = StateNotifierProvider<StockAnalysisNotifier, AsyncValue<AIAnalysisResult?>>((ref) {
  final repository = ref.read(aiSuggestionRepositoryProvider);
  return StockAnalysisNotifier(repository);
});

// AI建议操作提供者
class AISuggestionNotifier extends StateNotifier<AsyncValue<void>> {
  AISuggestionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  final AISuggestionRepository _repository;
  final Ref _ref;

  Future<AISuggestion> saveSuggestion({
    required String userId,
    required AIAnalysisResult analysis,
  }) async {
    state = const AsyncValue.loading();

    try {
      final suggestion = await _repository.createAndSaveSuggestion(
        userId: userId,
        analysis: analysis,
      );

      // 刷新建议列表
      _ref.invalidate(userAISuggestionsProvider);
      _ref.invalidate(pendingAISuggestionsProvider);

      state = const AsyncValue.data(null);
      return suggestion;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> markAsExecuted(String suggestionId, String transactionId) async {
    state = const AsyncValue.loading();

    try {
      await _repository.markAsExecuted(suggestionId, transactionId);

      // 刷新建议列表
      _ref.invalidate(userAISuggestionsProvider);
      _ref.invalidate(pendingAISuggestionsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsIgnored(String suggestionId, String? userNotes) async {
    state = const AsyncValue.loading();

    try {
      await _repository.markAsIgnored(suggestionId, userNotes);

      // 刷新建议列表
      _ref.invalidate(userAISuggestionsProvider);
      _ref.invalidate(pendingAISuggestionsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSuggestion(String id) async {
    state = const AsyncValue.loading();

    try {
      await _repository.deleteSuggestion(id);

      // 刷新建议列表
      _ref.invalidate(userAISuggestionsProvider);
      _ref.invalidate(pendingAISuggestionsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSuggestion(AISuggestion suggestion) async {
    state = const AsyncValue.loading();

    try {
      await _repository.updateSuggestion(suggestion);

      // 刷新建议列表
      _ref.invalidate(userAISuggestionsProvider);
      _ref.invalidate(pendingAISuggestionsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final aiSuggestionNotifierProvider = StateNotifierProvider<AISuggestionNotifier, AsyncValue<void>>((ref) {
  final repository = ref.read(aiSuggestionRepositoryProvider);
  return AISuggestionNotifier(repository, ref);
});

// 特定股票建议提供者
final stockSuggestionsProvider = FutureProvider.family<List<AISuggestion>, String>((ref, stockCode) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final repository = ref.read(aiSuggestionRepositoryProvider);
  return await repository.getStockSuggestions(user.id, stockCode);
});

// 建议详情提供者
final suggestionDetailProvider = FutureProvider.family<AISuggestion?, String>((ref, suggestionId) async {
  final repository = ref.read(aiSuggestionRepositoryProvider);
  return await repository.getSuggestionById(suggestionId);
});

// AI服务配置提供者
final aiServiceConfigProvider = FutureProvider<String>((ref) async {
  final repository = ref.read(aiSuggestionRepositoryProvider);
  return await repository.getAIServiceUrl();
});

// AI服务配置管理器
class AIServiceConfigNotifier extends StateNotifier<AsyncValue<void>> {
  AIServiceConfigNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  final AISuggestionRepository _repository;
  final Ref _ref;

  Future<void> updateServiceUrl(String url) async {
    state = const AsyncValue.loading();

    try {
      await _repository.setAIServiceUrl(url);

      // 刷新相关状态
      _ref.invalidate(aiServiceConfigProvider);
      _ref.invalidate(aiServiceStatusProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> resetToDefault() async {
    state = const AsyncValue.loading();

    try {
      await _repository.resetAIServiceUrl();

      // 刷新相关状态
      _ref.invalidate(aiServiceConfigProvider);
      _ref.invalidate(aiServiceStatusProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final aiServiceConfigNotifierProvider = StateNotifierProvider<AIServiceConfigNotifier, AsyncValue<void>>((ref) {
  final repository = ref.read(aiSuggestionRepositoryProvider);
  return AIServiceConfigNotifier(repository, ref);
});

