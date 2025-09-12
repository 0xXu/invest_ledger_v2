/// 数字格式化工具类
class NumberFormatter {
  /// 格式化货币金额，自动处理大数字的显示
  /// 
  /// 规则：
  /// - >= 1亿：显示为 ¥X.XX亿
  /// - >= 1万：显示为 ¥X.XX万  
  /// - >= 1千：显示为 ¥X.XXk
  /// - < 1千：显示为完整数字
  static String formatCurrency(double value, {
    bool showSign = true,
    int decimalPlaces = 2,
  }) {
    final absValue = value.abs();
    final sign = value >= 0 
      ? (showSign ? '+' : '') 
      : '-';
    
    // 处理亿级别
    if (absValue >= 100000000) {
      final formatted = (absValue / 100000000).toStringAsFixed(decimalPlaces);
      return '$sign¥$formatted亿';
    }
    // 处理万级别
    else if (absValue >= 10000) {
      final formatted = (absValue / 10000).toStringAsFixed(decimalPlaces);
      return '$sign¥$formatted万';
    }
    // 处理千级别
    else if (absValue >= 1000) {
      final formatted = (absValue / 1000).toStringAsFixed(decimalPlaces);
      return '$sign¥${formatted}k';
    }
    // 小于1000，显示完整数字
    else {
      return '$sign¥${absValue.toStringAsFixed(decimalPlaces)}';
    }
  }

  /// 格式化百分比
  static String formatPercentage(double value, {int decimalPlaces = 1}) {
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }

  /// 格式化整数（股票数、交易笔数等）
  static String formatInteger(int value) {
    if (value >= 10000) {
      final formatted = (value / 10000.0).toStringAsFixed(1);
      // 如果小数部分是.0，则不显示
      final cleanFormatted = formatted.endsWith('.0') 
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
      return '${cleanFormatted}万';
    } else if (value >= 1000) {
      final formatted = (value / 1000.0).toStringAsFixed(1);
      // 如果小数部分是.0，则不显示
      final cleanFormatted = formatted.endsWith('.0') 
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
      return '${cleanFormatted}k';
    } else {
      return value.toString();
    }
  }

  /// 智能格式化数字（根据类型自动选择格式）
  static String formatSmart(dynamic value) {
    if (value is double) {
      return formatCurrency(value);
    } else if (value is int) {
      return formatInteger(value);
    } else {
      return value.toString();
    }
  }

  /// 获取数字的简化显示长度（估算字符数，用于布局计算）
  static int getDisplayLength(double value) {
    final formatted = formatCurrency(value, showSign: false);
    return formatted.length;
  }
}