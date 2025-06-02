import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/ai_analysis_result.dart';
import '../../providers/ai_suggestion_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../providers/loading_provider.dart';
import '../../widgets/refresh_button.dart';
import 'analysis_result_page.dart';
import 'ai_config_page.dart';
import 'analysis_history_page.dart';

class AIAnalysisPage extends ConsumerStatefulWidget {
  const AIAnalysisPage({super.key});

  @override
  ConsumerState<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends ConsumerState<AIAnalysisPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final _stockCodeController = TextEditingController();
  final _initialCapitalController = TextEditingController(text: '100000');
  final _numOfNewsController = TextEditingController(text: '5');
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showReasoning = true;

  @override
  void dispose() {
    _stockCodeController.dispose();
    _initialCapitalController.dispose();
    _numOfNewsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    if (_formKey.currentState?.validate() != true) return;

    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      _showErrorSnackBar('请先登录');
      return;
    }

    final stockCode = _stockCodeController.text.trim();
    final initialCapital = double.tryParse(_initialCapitalController.text) ?? 100000.0;
    final numOfNews = int.tryParse(_numOfNewsController.text) ?? 5;
    final startDate = _startDateController.text.trim().isEmpty ? null : _startDateController.text.trim();
    final endDate = _endDateController.text.trim().isEmpty ? null : _endDateController.text.trim();

    try {
      // 使用全局加载状态
      ref.read(globalLoadingProvider.notifier).show('正在启动AI分析...');

      await ref.read(stockAnalysisProvider.notifier).analyzeStock(
        stockCode: stockCode,
        showReasoning: _showReasoning,
        initialCapital: initialCapital,
        numOfNews: numOfNews,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        ref.read(globalLoadingProvider.notifier).hide();

        // 检查分析结果
        final analysisState = ref.read(stockAnalysisProvider);
        analysisState.when(
          data: (result) {
            if (result != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AnalysisResultPage(result: result),
                ),
              );
            }
          },
          loading: () {},
          error: (error, stack) {
            _showErrorSnackBar('分析失败: $error');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(globalLoadingProvider.notifier).hide();
        _showErrorSnackBar('分析失败: $e');
      }
    }
  }

  Future<void> _selectDate(TextEditingController controller, String title) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: title,
    );

    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0]; // YYYY-MM-DD format
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
    super.build(context);

    final aiServiceStatusAsync = ref.watch(aiServiceStatusProvider);
    final stockAnalysisAsync = ref.watch(stockAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI股票分析'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history),
            tooltip: '分析历史',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AnalysisHistoryPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: 'AI配置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AIConfigPage(),
                ),
              );
            },
          ),
          RefreshButton.icon(
            onRefresh: () async {
              ref.invalidate(aiServiceStatusProvider);
            },
            loadingMessage: '正在检查AI服务状态...',
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI服务状态卡片
              _buildServiceStatusCard(aiServiceStatusAsync),
              const SizedBox(height: 16),

              // 分析输入表单
              _buildAnalysisForm(),
              const SizedBox(height: 16),

              // 分析参数配置
              _buildParametersCard(),
              const SizedBox(height: 24),

              // 开始分析按钮
              _buildAnalysisButton(aiServiceStatusAsync, stockAnalysisAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard(AsyncValue<bool> statusAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.activity, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI服务状态',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            statusAsync.when(
              data: (isAvailable) => Row(
                children: [
                  Icon(
                    isAvailable ? LucideIcons.checkCircle : LucideIcons.xCircle,
                    color: isAvailable ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? '服务正常' : '服务不可用',
                    style: TextStyle(
                      color: isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isAvailable) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AIConfigPage(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.settings, size: 16),
                      label: const Text('配置'),
                    ),
                  ],
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('检查中...'),
                ],
              ),
              error: (error, stack) => Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '检查失败: $error',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.search, size: 20),
                const SizedBox(width: 8),
                Text(
                  '股票分析',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockCodeController,
              decoration: const InputDecoration(
                labelText: '股票代码',
                hintText: '例如：000001',
                prefixIcon: Icon(LucideIcons.trendingUp),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入股票代码';
                }
                if (value.trim().length != 6) {
                  return '股票代码应为6位数字';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  '分析参数',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 显示推理过程开关
            SwitchListTile(
              title: const Text('显示推理过程'),
              subtitle: const Text('显示各Agent的详细分析过程'),
              value: _showReasoning,
              onChanged: (value) {
                setState(() {
                  _showReasoning = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // 初始资金输入
            TextFormField(
              controller: _initialCapitalController,
              decoration: const InputDecoration(
                labelText: '初始资金',
                hintText: '100000',
                prefixIcon: Icon(LucideIcons.dollarSign),
                border: OutlineInputBorder(),
                suffixText: '元',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入初始资金';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '请输入有效的金额';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 新闻数量输入
            TextFormField(
              controller: _numOfNewsController,
              decoration: const InputDecoration(
                labelText: '新闻数量',
                hintText: '5',
                prefixIcon: Icon(LucideIcons.newspaper),
                border: OutlineInputBorder(),
                suffixText: '条',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入新闻数量';
                }
                final num = int.tryParse(value);
                if (num == null || num < 1 || num > 100) {
                  return '新闻数量应在1-100之间';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 日期范围选择
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: '开始日期（可选）',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: const Icon(LucideIcons.calendar),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _startDateController.clear();
                        },
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController, '选择开始日期'),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final date = DateTime.tryParse(value);
                        if (date == null) {
                          return '请输入有效的日期格式';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      labelText: '结束日期（可选）',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: const Icon(LucideIcons.calendar),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _endDateController.clear();
                        },
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_endDateController, '选择结束日期'),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final date = DateTime.tryParse(value);
                        if (date == null) {
                          return '请输入有效的日期格式';
                        }
                        // 检查结束日期是否在开始日期之后
                        if (_startDateController.text.isNotEmpty) {
                          final startDate = DateTime.tryParse(_startDateController.text);
                          if (startDate != null && date.isBefore(startDate)) {
                            return '结束日期不能早于开始日期';
                          }
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisButton(AsyncValue<bool> statusAsync, AsyncValue<AIAnalysisResult?> analysisAsync) {
    return statusAsync.when(
      data: (isServiceAvailable) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: isServiceAvailable && !analysisAsync.isLoading
              ? _startAnalysis
              : null,
          icon: analysisAsync.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.play),
          label: Text(
            analysisAsync.isLoading
                ? '分析中...'
                : isServiceAvailable
                    ? '开始AI分析'
                    : '服务不可用',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isServiceAvailable
                ? Theme.of(context).primaryColor
                : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      loading: () => const SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('检查服务状态...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.alertCircle),
          label: const Text('服务检查失败'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}