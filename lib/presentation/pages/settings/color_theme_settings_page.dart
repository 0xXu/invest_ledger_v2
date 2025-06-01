import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/color_theme_setting.dart';
import '../../providers/color_theme_provider.dart';

class ColorThemeSettingsPage extends ConsumerStatefulWidget {
  const ColorThemeSettingsPage({super.key});

  @override
  ConsumerState<ColorThemeSettingsPage> createState() => _ColorThemeSettingsPageState();
}

class _ColorThemeSettingsPageState extends ConsumerState<ColorThemeSettingsPage> {
  Color? _customProfitColor;
  Color? _customLossColor;

  @override
  void initState() {
    super.initState();
    _loadCustomColors();
  }

  Future<void> _loadCustomColors() async {
    final notifier = ref.read(colorThemeNotifierProvider.notifier);
    final profitColor = await notifier.getCustomProfitColor();
    final lossColor = await notifier.getCustomLossColor();
    
    if (mounted) {
      setState(() {
        _customProfitColor = profitColor;
        _customLossColor = lossColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSetting = ref.watch(colorThemeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('盈亏颜色设置'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 说明卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.info, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '颜色方案说明',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '不同地区对股票盈亏颜色的理解不同：\n'
                    '• 中国风格：红色表示上涨/盈利，绿色表示下跌/亏损\n'
                    '• 西方风格：绿色表示上涨/盈利，红色表示下跌/亏损\n'
                    '• 自定义：您可以选择任意颜色组合',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 颜色方案选择
          Text(
            '选择颜色方案',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 中国风格
          _buildColorSchemeOption(
            scheme: ProfitLossColorScheme.chinese,
            currentScheme: colorSetting.colorScheme,
            onTap: () => _setColorScheme(ProfitLossColorScheme.chinese),
          ),
          const SizedBox(height: 12),

          // 西方风格
          _buildColorSchemeOption(
            scheme: ProfitLossColorScheme.western,
            currentScheme: colorSetting.colorScheme,
            onTap: () => _setColorScheme(ProfitLossColorScheme.western),
          ),
          const SizedBox(height: 12),

          // 自定义风格
          _buildColorSchemeOption(
            scheme: ProfitLossColorScheme.custom,
            currentScheme: colorSetting.colorScheme,
            onTap: () => _setColorScheme(ProfitLossColorScheme.custom),
          ),

          // 自定义颜色设置
          if (colorSetting.colorScheme == ProfitLossColorScheme.custom) ...[
            const SizedBox(height: 24),
            Text(
              '自定义颜色',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomColorSettings(),
          ],

          const SizedBox(height: 24),

          // 预览卡片
          _buildPreviewCard(colorSetting),
        ],
      ),
    );
  }

  Widget _buildColorSchemeOption({
    required ProfitLossColorScheme scheme,
    required ProfitLossColorScheme currentScheme,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = scheme == currentScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 选择指示器
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // 方案信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheme.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 颜色预览
              Row(
                children: [
                  _buildColorPreview(scheme.profitColor, '+100'),
                  const SizedBox(width: 8),
                  _buildColorPreview(scheme.lossColor, '-100'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomColorSettings() {
    return Column(
      children: [
        // 盈利颜色设置
        _buildColorPicker(
          title: '盈利颜色',
          color: _customProfitColor ?? ProfitLossColorScheme.custom.profitColor,
          onColorChanged: (color) {
            setState(() => _customProfitColor = color);
            _setCustomColor(profitColor: color);
          },
        ),
        const SizedBox(height: 16),

        // 亏损颜色设置
        _buildColorPicker(
          title: '亏损颜色',
          color: _customLossColor ?? ProfitLossColorScheme.custom.lossColor,
          onColorChanged: (color) {
            setState(() => _customLossColor = color);
            _setCustomColor(lossColor: color);
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker({
    required String title,
    required Color color,
    required ValueChanged<Color> onColorChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(title),
        ),
        GestureDetector(
          onTap: () => _showColorPicker(color, onColorChanged),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ColorThemeSetting setting) {
    final colors = ProfitLossColors(scheme: setting.colorScheme);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '效果预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPreviewItem(
                  '盈利 +1,250.00',
                  colors.getProfitColor(),
                  colors.getIconByValue(1250),
                ),
                _buildPreviewItem(
                  '亏损 -850.00',
                  colors.getLossColor(),
                  colors.getIconByValue(-850),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String text, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _setColorScheme(ProfitLossColorScheme scheme) async {
    await ref.read(colorThemeNotifierProvider.notifier).setColorScheme(scheme);
  }

  Future<void> _setCustomColor({Color? profitColor, Color? lossColor}) async {
    await ref.read(colorThemeNotifierProvider.notifier).setCustomColors(
      profitColor: profitColor,
      lossColor: lossColor,
    );
  }
}

// 简单的颜色选择器
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  static const List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.lime,
    Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: pickerColor == color ? Colors.black : Colors.grey.shade300,
                width: pickerColor == color ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
