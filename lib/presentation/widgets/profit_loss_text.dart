import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';

import '../../data/models/color_theme_setting.dart';
import '../providers/color_theme_provider.dart';

/// 盈亏文本组件 - 根据设置自动显示正确的颜色
class ProfitLossText extends ConsumerWidget {
  final double value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final bool showSign;
  final bool showIcon;
  final double? iconSize;

  const ProfitLossText({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix = '',
    this.decimalPlaces = 2,
    this.showSign = true,
    this.showIcon = false,
    this.iconSize,
  });

  /// 从 Decimal 创建
  factory ProfitLossText.fromDecimal({
    Key? key,
    required Decimal value,
    TextStyle? style,
    String? prefix,
    String? suffix = '',
    int decimalPlaces = 2,
    bool showSign = true,
    bool showIcon = false,
    double? iconSize,
  }) {
    return ProfitLossText(
      key: key,
      value: value.toDouble(),
      style: style,
      prefix: prefix,
      suffix: suffix,
      decimalPlaces: decimalPlaces,
      showSign: showSign,
      showIcon: showIcon,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => _buildText(context, colors),
      loading: () => _buildText(context, _getDefaultColors()),
      error: (_, __) => _buildText(context, _getDefaultColors()),
    );
  }

  Widget _buildText(BuildContext context, ProfitLossColors colors) {
    final color = colors.getColorByValue(value);
    final icon = colors.getIconByValue(value);
    
    final formattedValue = _formatValue();
    final textStyle = (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    if (showIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize ?? (textStyle?.fontSize ?? 14),
          ),
          const SizedBox(width: 4),
          Text(
            formattedValue,
            style: textStyle,
          ),
        ],
      );
    }

    return Text(
      formattedValue,
      style: textStyle,
    );
  }

  String _formatValue() {
    final absValue = value.abs();
    final formattedNumber = absValue.toStringAsFixed(decimalPlaces);
    
    String result = '';
    
    if (prefix != null) {
      result += prefix!;
    }
    
    if (showSign) {
      if (value > 0) {
        result += '+';
      } else if (value < 0) {
        result += '-';
      }
    }
    
    result += formattedNumber;
    
    if (suffix != null) {
      result += suffix!;
    }
    
    return result;
  }

  ProfitLossColors _getDefaultColors() {
    return const ProfitLossColors(scheme: ProfitLossColorScheme.chinese);
  }
}

/// 盈亏百分比文本组件
class ProfitLossPercentageText extends ConsumerWidget {
  final double percentage;
  final TextStyle? style;
  final bool showIcon;
  final double? iconSize;

  const ProfitLossPercentageText({
    super.key,
    required this.percentage,
    this.style,
    this.showIcon = false,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfitLossText(
      value: percentage,
      style: style,
      suffix: '%',
      decimalPlaces: 2,
      showSign: true,
      showIcon: showIcon,
      iconSize: iconSize,
    );
  }
}

/// 盈亏金额文本组件
class ProfitLossAmountText extends ConsumerWidget {
  final double amount;
  final TextStyle? style;
  final String currency;
  final bool showIcon;
  final double? iconSize;

  const ProfitLossAmountText({
    super.key,
    required this.amount,
    this.style,
    this.currency = '¥',
    this.showIcon = false,
    this.iconSize,
  });

  /// 从 Decimal 创建
  factory ProfitLossAmountText.fromDecimal({
    Key? key,
    required Decimal amount,
    TextStyle? style,
    String currency = '¥',
    bool showIcon = false,
    double? iconSize,
  }) {
    return ProfitLossAmountText(
      key: key,
      amount: amount.toDouble(),
      style: style,
      currency: currency,
      showIcon: showIcon,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfitLossText(
      value: amount,
      style: style,
      prefix: currency,
      decimalPlaces: 2,
      showSign: true,
      showIcon: showIcon,
      iconSize: iconSize,
    );
  }
}

/// 盈亏指示器组件 - 只显示图标和颜色
class ProfitLossIndicator extends ConsumerWidget {
  final double value;
  final double size;

  const ProfitLossIndicator({
    super.key,
    required this.value,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => Icon(
        colors.getIconByValue(value),
        color: colors.getColorByValue(value),
        size: size,
      ),
      loading: () => Icon(
        Icons.remove,
        color: Colors.grey,
        size: size,
      ),
      error: (_, __) => Icon(
        Icons.error,
        color: Colors.grey,
        size: size,
      ),
    );
  }
}

/// 盈亏背景容器 - 使用盈亏颜色作为背景
class ProfitLossContainer extends ConsumerWidget {
  final double value;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double opacity;

  const ProfitLossContainer({
    super.key,
    required this.value,
    required this.child,
    this.padding,
    this.borderRadius,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.getColorByValue(value).withOpacity(opacity),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          border: Border.all(
            color: colors.getColorByValue(value).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: child,
      ),
      loading: () => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(opacity),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      ),
      error: (_, __) => child,
    );
  }
}
