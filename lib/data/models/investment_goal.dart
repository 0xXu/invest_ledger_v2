import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'investment_goal.freezed.dart';
part 'investment_goal.g.dart';

@freezed
class InvestmentGoal with _$InvestmentGoal {
  const factory InvestmentGoal({
    String? id,
    required String userId,
    required GoalType type,
    required GoalPeriod period,
    required int year,
    int? month, // null for yearly goals
    required Decimal targetAmount,
    String? description,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted, // 软删除标记
  }) = _InvestmentGoal;

  factory InvestmentGoal.fromJson(Map<String, dynamic> json) =>
      _$InvestmentGoalFromJson(json);
}

enum GoalType {
  @JsonValue('profit')
  profit, // 盈利目标
  @JsonValue('roi')
  roi, // ROI目标
}

enum GoalPeriod {
  @JsonValue('monthly')
  monthly, // 月度目标
  @JsonValue('yearly')
  yearly, // 年度目标
}

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.profit:
        return '盈利目标';
      case GoalType.roi:
        return 'ROI目标';
    }
  }

  String get unit {
    switch (this) {
      case GoalType.profit:
        return '¥';
      case GoalType.roi:
        return '%';
    }
  }
}

extension GoalPeriodExtension on GoalPeriod {
  String get displayName {
    switch (this) {
      case GoalPeriod.monthly:
        return '月度';
      case GoalPeriod.yearly:
        return '年度';
    }
  }
}
