import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_config.freezed.dart';
part 'ai_config.g.dart';

@freezed
class AIConfig with _$AIConfig {
  const factory AIConfig({
    required String baseUrl,
    String? geminiApiKey,
    @Default('gemini-1.5-flash') String geminiModel,
    String? openaiApiKey,
    String? openaiBaseUrl,
    @Default('gpt-3.5-turbo') String openaiModel,
  }) = _AIConfig;

  factory AIConfig.fromJson(Map<String, dynamic> json) =>
      _$AIConfigFromJson(json);
}

enum AIProvider {
  gemini,
  openai,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.gemini:
        return 'Google Gemini';
      case AIProvider.openai:
        return 'OpenAI Compatible';
    }
  }
  
  String get description {
    switch (this) {
      case AIProvider.gemini:
        return '使用Google Gemini API';
      case AIProvider.openai:
        return '使用OpenAI兼容的API';
    }
  }
}
