import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/color_theme_setting.dart';

part 'color_theme_provider.g.dart';

@riverpod
class ColorThemeNotifier extends _$ColorThemeNotifier {
  static const String _colorSchemeKey = 'profit_loss_color_scheme';
  static const String _customProfitColorKey = 'custom_profit_color';
  static const String _customLossColorKey = 'custom_loss_color';

  @override
  ColorThemeSetting build() {
    _loadSettings();
    // 默认使用中国风格（红涨绿跌）
    return const ColorThemeSetting(
      colorScheme: ProfitLossColorScheme.chinese,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final schemeString = prefs.getString(_colorSchemeKey);
    final customProfitColorValue = prefs.getInt(_customProfitColorKey);
    final customLossColorValue = prefs.getInt(_customLossColorKey);

    ProfitLossColorScheme scheme = ProfitLossColorScheme.chinese;
    if (schemeString != null) {
      scheme = ProfitLossColorScheme.values.firstWhere(
        (e) => e.name == schemeString,
        orElse: () => ProfitLossColorScheme.chinese,
      );
    }

    state = ColorThemeSetting(
      colorScheme: scheme,
      useCustomColors: scheme == ProfitLossColorScheme.custom,
    );
  }

  Future<void> setColorScheme(ProfitLossColorScheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, scheme.name);
    
    state = state.copyWith(
      colorScheme: scheme,
      useCustomColors: scheme == ProfitLossColorScheme.custom,
    );
  }

  Future<void> setCustomColors({
    Color? profitColor,
    Color? lossColor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (profitColor != null) {
      await prefs.setInt(_customProfitColorKey, profitColor.value);
    }
    
    if (lossColor != null) {
      await prefs.setInt(_customLossColorKey, lossColor.value);
    }

    // 如果设置了自定义颜色，自动切换到自定义方案
    if (state.colorScheme != ProfitLossColorScheme.custom) {
      await setColorScheme(ProfitLossColorScheme.custom);
    }
  }

  Future<Color?> getCustomProfitColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_customProfitColorKey);
    return colorValue != null ? Color(colorValue) : null;
  }

  Future<Color?> getCustomLossColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_customLossColorKey);
    return colorValue != null ? Color(colorValue) : null;
  }
}

// 便捷的颜色获取 Provider
@riverpod
Future<ProfitLossColors> profitLossColors(ProfitLossColorsRef ref) async {
  final setting = ref.watch(colorThemeNotifierProvider);
  final notifier = ref.read(colorThemeNotifierProvider.notifier);
  
  Color? customProfitColor;
  Color? customLossColor;
  
  if (setting.colorScheme == ProfitLossColorScheme.custom) {
    customProfitColor = await notifier.getCustomProfitColor();
    customLossColor = await notifier.getCustomLossColor();
  }
  
  return ProfitLossColors(
    scheme: setting.colorScheme,
    customProfitColor: customProfitColor,
    customLossColor: customLossColor,
  );
}

// 同步版本的颜色获取（用于需要立即获取颜色的场景）
@riverpod
ProfitLossColors profitLossColorsSync(ProfitLossColorsSyncRef ref) {
  final setting = ref.watch(colorThemeNotifierProvider);
  
  return ProfitLossColors(
    scheme: setting.colorScheme,
    // 同步版本使用默认颜色，异步版本会加载自定义颜色
  );
}
