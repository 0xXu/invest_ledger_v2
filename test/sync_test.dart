import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:invest_ledger/data/models/transaction.dart';
import 'package:invest_ledger/data/models/investment_goal.dart';

void main() {
  group('数据同步修复测试', () {
    test('Transaction模型应该支持isDeleted字段', () {
      final transaction = Transaction(
        userId: 'test-user',
        date: DateTime.now(),
        stockCode: 'AAPL',
        stockName: 'Apple Inc.',
        amount: Decimal.fromInt(100),
        unitPrice: Decimal.fromInt(150),
        profitLoss: Decimal.fromInt(1000),
        createdAt: DateTime.now(),
        isDeleted: true,
      );

      expect(transaction.isDeleted, true);
      
      // 测试默认值
      final transaction2 = Transaction(
        userId: 'test-user',
        date: DateTime.now(),
        stockCode: 'AAPL',
        stockName: 'Apple Inc.',
        amount: Decimal.fromInt(100),
        unitPrice: Decimal.fromInt(150),
        profitLoss: Decimal.fromInt(1000),
        createdAt: DateTime.now(),
      );

      expect(transaction2.isDeleted, false);
    });

    test('InvestmentGoal模型应该支持isDeleted字段', () {
      final goal = InvestmentGoal(
        userId: 'test-user',
        type: GoalType.profit,
        period: GoalPeriod.monthly,
        year: 2024,
        month: 12,
        targetAmount: Decimal.fromInt(10000),
        createdAt: DateTime.now(),
        isDeleted: true,
      );

      expect(goal.isDeleted, true);
      
      // 测试默认值
      final goal2 = InvestmentGoal(
        userId: 'test-user',
        type: GoalType.profit,
        period: GoalPeriod.monthly,
        year: 2024,
        month: 12,
        targetAmount: Decimal.fromInt(10000),
        createdAt: DateTime.now(),
      );

      expect(goal2.isDeleted, false);
    });

    test('Transaction JSON序列化应该包含isDeleted字段', () {
      final transaction = Transaction(
        id: 'test-id',
        userId: 'test-user',
        date: DateTime.parse('2024-01-01'),
        stockCode: 'AAPL',
        stockName: 'Apple Inc.',
        amount: Decimal.fromInt(100),
        unitPrice: Decimal.fromInt(150),
        profitLoss: Decimal.fromInt(1000),
        createdAt: DateTime.parse('2024-01-01'),
        isDeleted: true,
      );

      final json = transaction.toJson();
      expect(json['isDeleted'], true);

      final fromJson = Transaction.fromJson(json);
      expect(fromJson.isDeleted, true);
    });

    test('InvestmentGoal JSON序列化应该包含isDeleted字段', () {
      final goal = InvestmentGoal(
        id: 'test-id',
        userId: 'test-user',
        type: GoalType.profit,
        period: GoalPeriod.monthly,
        year: 2024,
        month: 12,
        targetAmount: Decimal.fromInt(10000),
        createdAt: DateTime.parse('2024-01-01'),
        isDeleted: true,
      );

      final json = goal.toJson();
      expect(json['isDeleted'], true);

      final fromJson = InvestmentGoal.fromJson(json);
      expect(fromJson.isDeleted, true);
    });
  });
}
