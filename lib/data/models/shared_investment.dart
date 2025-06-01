import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'shared_investment.freezed.dart';
part 'shared_investment.g.dart';

@freezed
class SharedInvestment with _$SharedInvestment {
  const factory SharedInvestment({
    required String id,
    required String name,
    required String stockCode,       // 股票代码
    required String stockName,       // 股票名称
    required Decimal totalAmount,    // 总投资金额 (CNY)
    required Decimal totalShares,    // 总股数
    required Decimal initialPrice,   // 初始价格 (CNY)
    Decimal? currentPrice,           // 当前价格 (CNY)
    Decimal? sellAmount,             // 卖出总金额 (CNY)
    required DateTime createdDate,
    @Default(SharedInvestmentStatus.active) SharedInvestmentStatus status,
    String? notes,
    @Default([]) List<SharedInvestmentParticipant> participants,
  }) = _SharedInvestment;

  factory SharedInvestment.fromJson(Map<String, dynamic> json) =>
      _$SharedInvestmentFromJson(json);
}

@freezed
class SharedInvestmentParticipant with _$SharedInvestmentParticipant {
  const factory SharedInvestmentParticipant({
    required String id,
    required String sharedInvestmentId,
    required String userId,
    required String userName,
    required Decimal investmentAmount,
    required Decimal shares,
    required Decimal profitLoss,
    String? transactionId,
  }) = _SharedInvestmentParticipant;

  factory SharedInvestmentParticipant.fromJson(Map<String, dynamic> json) =>
      _$SharedInvestmentParticipantFromJson(json);
}

enum SharedInvestmentStatus {
  active,
  completed,
  cancelled,
}
