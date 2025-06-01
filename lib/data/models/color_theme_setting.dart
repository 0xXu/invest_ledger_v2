import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'color_theme_setting.freezed.dart';
part 'color_theme_setting.g.dart';

@freezed
class ColorThemeSetting with _$ColorThemeSetting {
  const factory ColorThemeSetting({
    @Default(ProfitLossColorScheme.chinese) ProfitLossColorScheme colorScheme,
    @Default(true) bool useCustomColors,
  }) = _ColorThemeSetting;

  factory ColorThemeSetting.fromJson(Map<String, dynamic> json) =>
      _$ColorThemeSettingFromJson(json);
}

enum ProfitLossColorScheme {
  @JsonValue('chinese')
  chinese, // 中国风格：红涨绿跌
  @JsonValue('western')
  western, // 西方风格：绿涨红跌
  @JsonValue('custom')
  custom, // 自定义颜色
}

extension ProfitLossColorSchemeExtension on ProfitLossColorScheme {
  String get displayName {
    switch (this) {
      case ProfitLossColorScheme.chinese:
        return '中国风格';
      case ProfitLossColorScheme.western:
        return '西方风格';
      case ProfitLossColorScheme.custom:
        return '自定义';
    }
  }

  String get description {
    switch (this) {
      case ProfitLossColorScheme.chinese:
        return '红色表示盈利，绿色表示亏损';
      case ProfitLossColorScheme.western:
        return '绿色表示盈利，红色表示亏损';
      case ProfitLossColorScheme.custom:
        return '使用自定义颜色方案';
    }
  }

  Color get profitColor {
    switch (this) {
      case ProfitLossColorScheme.chinese:
        return const Color(0xFFE53E3E); // 红色
      case ProfitLossColorScheme.western:
        return const Color(0xFF38A169); // 绿色
      case ProfitLossColorScheme.custom:
        return const Color(0xFF4CAF50); // 默认绿色
    }
  }

  Color get lossColor {
    switch (this) {
      case ProfitLossColorScheme.chinese:
        return const Color(0xFF38A169); // 绿色
      case ProfitLossColorScheme.western:
        return const Color(0xFFE53E3E); // 红色
      case ProfitLossColorScheme.custom:
        return const Color(0xFFF44336); // 默认红色
    }
  }

  IconData get profitIcon {
    switch (this) {
      case ProfitLossColorScheme.chinese:
        return Icons.trending_up;
      case ProfitLossColorScheme.western:
        return Icons.trending_up;
      case ProfitLossColorScheme.custom:
        return Icons.trending_up;
    }
  }

  IconData get lossIcon {
    switch (this) {
      case ProfitLossColorScheme.chinese:
        return Icons.trending_down;
      case ProfitLossColorScheme.western:
        return Icons.trending_down;
      case ProfitLossColorScheme.custom:
        return Icons.trending_down;
    }
  }
}

/// 盈亏颜色工具类
class ProfitLossColors {
  final ProfitLossColorScheme scheme;
  final Color? customProfitColor;
  final Color? customLossColor;

  const ProfitLossColors({
    required this.scheme,
    this.customProfitColor,
    this.customLossColor,
  });

  /// 获取盈利颜色
  Color getProfitColor() {
    if (scheme == ProfitLossColorScheme.custom && customProfitColor != null) {
      return customProfitColor!;
    }
    return scheme.profitColor;
  }

  /// 获取亏损颜色
  Color getLossColor() {
    if (scheme == ProfitLossColorScheme.custom && customLossColor != null) {
      return customLossColor!;
    }
    return scheme.lossColor;
  }

  /// 根据数值获取颜色
  Color getColorByValue(double value) {
    if (value > 0) {
      return getProfitColor();
    } else if (value < 0) {
      return getLossColor();
    } else {
      return Colors.grey;
    }
  }

  /// 根据数值获取图标
  IconData getIconByValue(double value) {
    if (value > 0) {
      return scheme.profitIcon;
    } else if (value < 0) {
      return scheme.lossIcon;
    } else {
      return Icons.remove;
    }
  }
}
