import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_result.freezed.dart';
part 'import_result.g.dart';

/// TXT导入结果
@freezed
class TxtImportResult with _$TxtImportResult {
  const factory TxtImportResult({
    required int totalLines,           // 总行数
    required int successCount,         // 成功导入数量
    required int duplicateCount,       // 重复数据数量
    required int errorCount,           // 错误数量
    required List<ImportError> errors, // 错误详情
    required String detectedFormat,    // 检测到的格式
  }) = _TxtImportResult;

  factory TxtImportResult.fromJson(Map<String, dynamic> json) =>
      _$TxtImportResultFromJson(json);
}

/// 导入错误信息
@freezed
class ImportError with _$ImportError {
  const factory ImportError({
    required int lineNumber,    // 行号
    required String lineContent, // 行内容
    required String errorType,   // 错误类型
    required String errorMessage, // 错误信息
  }) = _ImportError;

  factory ImportError.fromJson(Map<String, dynamic> json) =>
      _$ImportErrorFromJson(json);
}

/// 数据格式类型
enum TxtDataFormat {
  standard,     // 标准格式: 日期 股票代码 股票名称 数量 单价 备注
  profitLoss,   // 盈亏格式: 股票名称：盈XXX元，日期
  tabSeparated, // 制表符分隔
  commaSeparated, // 逗号分隔
  unknown,      // 未知格式
}

extension TxtDataFormatExtension on TxtDataFormat {
  String get description {
    switch (this) {
      case TxtDataFormat.standard:
        return '标准格式';
      case TxtDataFormat.profitLoss:
        return '盈亏记录格式';
      case TxtDataFormat.tabSeparated:
        return '制表符分隔格式';
      case TxtDataFormat.commaSeparated:
        return '逗号分隔格式';
      case TxtDataFormat.unknown:
        return '未知格式';
    }
  }
}

/// 去重策略
enum DuplicationStrategy {
  skip,      // 跳过重复数据
  replace,   // 替换重复数据
  keepBoth,  // 保留两条数据
}

/// 交易记录唯一性标识
class TransactionKey {
  final String userId;
  final DateTime date;
  final String stockCode;
  final String stockName;

  const TransactionKey({
    required this.userId,
    required this.date,
    required this.stockCode,
    required this.stockName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionKey &&
        other.userId == userId &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.stockCode == stockCode &&
        other.stockName == stockName;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      date.year,
      date.month,
      date.day,
      stockCode,
      stockName,
    );
  }

  @override
  String toString() {
    return 'TransactionKey(userId: $userId, date: ${date.toString().substring(0, 10)}, stockCode: $stockCode, stockName: $stockName)';
  }
}
