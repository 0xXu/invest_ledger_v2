import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../models/user.dart';
import '../../models/transaction.dart';

class SampleData {
  static const _uuid = Uuid();

  static Future<void> createSampleData() async {
    // 这个方法可以用来创建示例数据进行测试
    // 在实际应用中，这些数据会通过用户界面创建
  }

  static User createSampleUser() {
    return User(
      id: _uuid.v4(),
      name: '张三',
      email: 'zhangsan@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
  }

  static List<Transaction> createSampleTransactions(String userId) {
    final now = DateTime.now();
    
    return [
      Transaction(
        id: _uuid.v4(),
        userId: userId,
        date: now.subtract(const Duration(days: 5)),
        stockCode: '000001',
        stockName: '平安银行',
        amount: Decimal.fromInt(1000),
        unitPrice: Decimal.parse('12.50'),
        profitLoss: Decimal.parse('500.00'),
        tags: ['银行股', '蓝筹'],
        notes: '看好银行板块长期发展',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: _uuid.v4(),
        userId: userId,
        date: now.subtract(const Duration(days: 10)),
        stockCode: '000002',
        stockName: '万科A',
        amount: Decimal.fromInt(500),
        unitPrice: Decimal.parse('25.80'),
        profitLoss: Decimal.parse('-200.00'),
        tags: ['地产股'],
        notes: '地产调整期，长期持有',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Transaction(
        id: _uuid.v4(),
        userId: userId,
        date: now.subtract(const Duration(days: 15)),
        stockCode: '600036',
        stockName: '招商银行',
        amount: Decimal.fromInt(800),
        unitPrice: Decimal.parse('35.20'),
        profitLoss: Decimal.parse('1200.00'),
        tags: ['银行股', '优质股'],
        notes: '招行基本面优秀，继续持有',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Transaction(
        id: _uuid.v4(),
        userId: userId,
        date: now.subtract(const Duration(days: 20)),
        stockCode: '000858',
        stockName: '五粮液',
        amount: Decimal.fromInt(200),
        unitPrice: Decimal.parse('180.50'),
        profitLoss: Decimal.parse('800.00'),
        tags: ['白酒股', '消费'],
        notes: '白酒龙头，长期看好',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Transaction(
        id: _uuid.v4(),
        userId: userId,
        date: now.subtract(const Duration(days: 25)),
        stockCode: '300750',
        stockName: '宁德时代',
        amount: Decimal.fromInt(100),
        unitPrice: Decimal.parse('420.00'),
        profitLoss: Decimal.parse('-1500.00'),
        tags: ['新能源', '电池'],
        notes: '新能源汽车产业链核心',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    ];
  }
}
