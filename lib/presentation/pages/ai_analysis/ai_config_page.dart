import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_config.dart';
import '../../providers/ai_suggestion_provider.dart';
import '../../widgets/refresh_button.dart';

class AIConfigPage extends ConsumerStatefulWidget {
  const AIConfigPage({super.key});

  @override
  ConsumerState<AIConfigPage> createState() => _AIConfigPageState();
}

class _AIConfigPageState extends ConsumerState<AIConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();
  final _geminiModelController = TextEditingController();
  final _openaiApiKeyController = TextEditingController();
  final _openaiBaseUrlController = TextEditingController();
  final _openaiModelController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _geminiApiKeyController.dispose();
    _geminiModelController.dispose();
    _openaiApiKeyController.dispose();
    _openaiBaseUrlController.dispose();
    _openaiModelController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(aiSuggestionRepositoryProvider);
      final config = await repository.getAIConfig();

      _baseUrlController.text = config.baseUrl;
      _geminiApiKeyController.text = config.geminiApiKey ?? '';
      _geminiModelController.text = config.geminiModel;
      _openaiApiKeyController.text = config.openaiApiKey ?? '';
      _openaiBaseUrlController.text = config.openaiBaseUrl ?? '';
      _openaiModelController.text = config.openaiModel;
    } catch (e) {
      _showErrorSnackBar('加载配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = AIConfig(
        baseUrl: _baseUrlController.text.trim(),
        geminiApiKey: _geminiApiKeyController.text.trim().isEmpty
            ? null
            : _geminiApiKeyController.text.trim(),
        geminiModel: _geminiModelController.text.trim(),
        openaiApiKey: _openaiApiKeyController.text.trim().isEmpty
            ? null
            : _openaiApiKeyController.text.trim(),
        openaiBaseUrl: _openaiBaseUrlController.text.trim().isEmpty
            ? null
            : _openaiBaseUrlController.text.trim(),
        openaiModel: _openaiModelController.text.trim(),
      );

      final repository = ref.read(aiSuggestionRepositoryProvider);
      await repository.updateAIConfig(config);

      // 刷新服务状态
      ref.invalidate(aiServiceStatusProvider);

      _showSuccessSnackBar('配置保存成功');
    } catch (e) {
      _showErrorSnackBar('保存配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(aiSuggestionRepositoryProvider);
      await repository.resetAIConfig();

      // 重新加载配置
      await _loadCurrentConfig();

      // 刷新服务状态
      ref.invalidate(aiServiceStatusProvider);

      _showSuccessSnackBar('已重置为默认配置');
    } catch (e) {
      _showErrorSnackBar('重置配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(aiSuggestionRepositoryProvider);
      final isAvailable = await repository.isAIServiceAvailable();

      if (isAvailable) {
        _showSuccessSnackBar('连接测试成功');
      } else {
        _showErrorSnackBar('连接测试失败：服务不可用');
      }
    } catch (e) {
      _showErrorSnackBar('连接测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI服务配置'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.testTube),
            tooltip: '测试连接',
            onPressed: _isLoading ? null : _testConnection,
          ),
          RefreshButton.icon(
            onRefresh: _loadCurrentConfig,
            loadingMessage: '正在重新加载配置...',
            tooltip: '重新加载',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 服务配置
                    _buildServiceConfigCard(),
                    const SizedBox(height: 16),

                    // Gemini配置
                    _buildGeminiConfigCard(),
                    const SizedBox(height: 16),

                    // OpenAI兼容配置
                    _buildOpenAIConfigCard(),
                    const SizedBox(height: 24),

                    // 操作按钮
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServiceConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.server, size: 20),
                const SizedBox(width: 8),
                Text(
                  '服务配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: '服务地址',
                hintText: 'http://localhost:8000',
                prefixIcon: Icon(LucideIcons.globe),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入服务地址';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
                  return '请输入有效的URL (http://或https://)';
                }
                if (uri.host.isEmpty) {
                  return '请输入有效的主机地址';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.brain, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gemini配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _geminiApiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: '输入Gemini API Key',
                prefixIcon: Icon(LucideIcons.key),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _geminiModelController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: 'gemini-1.5-flash',
                prefixIcon: Icon(LucideIcons.cpu),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入模型名称';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAIConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.zap, size: 20),
                const SizedBox(width: 8),
                Text(
                  'OpenAI兼容配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openaiApiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: '输入OpenAI兼容API Key',
                prefixIcon: Icon(LucideIcons.key),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openaiBaseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://api.openai.com/v1',
                prefixIcon: Icon(LucideIcons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openaiModelController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: 'gpt-3.5-turbo',
                prefixIcon: Icon(LucideIcons.cpu),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入模型名称';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveConfig,
            icon: const Icon(LucideIcons.save),
            label: const Text('保存配置'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _resetToDefault,
            icon: const Icon(LucideIcons.rotateCcw),
            label: const Text('重置为默认'),
          ),
        ),
      ],
    );
  }
}
