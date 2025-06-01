import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    String? id,
    required String userId,
    required DateTime date,
    required String stockCode,        // 股票代码
    required String stockName,        // 股票名称
    required Decimal amount,          // 股数
    required Decimal unitPrice,       // 单价
    required Decimal profitLoss,      // 盈亏 (CNY)
    @Default([]) List<String> tags,
    String? notes,
    String? sharedInvestmentId,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
