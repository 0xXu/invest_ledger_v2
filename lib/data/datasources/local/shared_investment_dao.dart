import 'package:decimal/decimal.dart';

import '../../models/shared_investment.dart';
import '../../database/database_helper.dart';

class SharedInvestmentDao {
  static const String _tableName = 'shared_investments';
  static const String _participantsTableName = 'shared_investment_participants';

  Future<String> createSharedInvestment(SharedInvestment sharedInvestment) async {
    final db = await DatabaseHelper.database;
    final id = sharedInvestment.id;

    // 开始事务
    await db.transaction((txn) async {
      // 插入共享投资记录
      await txn.insert(_tableName, {
        'id': sharedInvestment.id,
        'name': sharedInvestment.name,
        'stock_code': sharedInvestment.stockCode,
        'stock_name': sharedInvestment.stockName,
        'total_amount': sharedInvestment.totalAmount.toString(),
        'total_shares': sharedInvestment.totalShares.toString(),
        'initial_price': sharedInvestment.initialPrice.toString(),
        'current_price': sharedInvestment.currentPrice?.toString(),
        'sell_amount': sharedInvestment.sellAmount?.toString(),
        'created_date': sharedInvestment.createdDate.toIso8601String(),
        'status': sharedInvestment.status.name,
        'notes': sharedInvestment.notes,
      });

      // 插入参与者记录
      for (final participant in sharedInvestment.participants) {
        await txn.insert(_participantsTableName, {
          'id': participant.id,
          'shared_investment_id': participant.sharedInvestmentId,
          'user_id': participant.userId,
          'user_name': participant.userName,
          'investment_amount': participant.investmentAmount.toString(),
          'shares': participant.shares.toString(),
          'profit_loss': participant.profitLoss.toString(),
          'transaction_id': participant.transactionId,
        });
      }
    });

    return id;
  }

  Future<SharedInvestment?> getSharedInvestmentById(String id) async {
    final db = await DatabaseHelper.database;

    // 获取共享投资基本信息
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // 获取参与者信息
    final participantMaps = await db.query(
      _participantsTableName,
      where: 'shared_investment_id = ?',
      whereArgs: [id],
    );

    return _mapToSharedInvestment(maps.first, participantMaps);
  }

  Future<List<SharedInvestment>> getAllSharedInvestments() async {
    final db = await DatabaseHelper.database;

    // 获取所有共享投资
    final maps = await db.query(_tableName, orderBy: 'created_date DESC');

    final List<SharedInvestment> sharedInvestments = [];

    for (final map in maps) {
      // 获取每个共享投资的参与者
      final participantMaps = await db.query(
        _participantsTableName,
        where: 'shared_investment_id = ?',
        whereArgs: [map['id']],
      );

      sharedInvestments.add(_mapToSharedInvestment(map, participantMaps));
    }

    return sharedInvestments;
  }

  Future<List<SharedInvestment>> getSharedInvestmentsByUserId(String userId) async {
    final db = await DatabaseHelper.database;

    // 通过参与者表查找用户参与的共享投资
    final participantMaps = await db.query(
      _participantsTableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final Set<String> sharedInvestmentIds = participantMaps
        .map((map) => map['shared_investment_id'] as String)
        .toSet();

    final List<SharedInvestment> sharedInvestments = [];

    for (final id in sharedInvestmentIds) {
      final sharedInvestment = await getSharedInvestmentById(id);
      if (sharedInvestment != null) {
        sharedInvestments.add(sharedInvestment);
      }
    }

    // 按创建时间排序
    sharedInvestments.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return sharedInvestments;
  }

  Future<void> updateSharedInvestment(SharedInvestment sharedInvestment) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      // 更新共享投资基本信息
      await txn.update(
        _tableName,
        {
          'name': sharedInvestment.name,
          'stock_code': sharedInvestment.stockCode,
          'stock_name': sharedInvestment.stockName,
          'total_amount': sharedInvestment.totalAmount.toString(),
          'total_shares': sharedInvestment.totalShares.toString(),
          'initial_price': sharedInvestment.initialPrice.toString(),
          'current_price': sharedInvestment.currentPrice?.toString(),
          'sell_amount': sharedInvestment.sellAmount?.toString(),
          'status': sharedInvestment.status.name,
          'notes': sharedInvestment.notes,
        },
        where: 'id = ?',
        whereArgs: [sharedInvestment.id],
      );

      // 删除旧的参与者记录
      await txn.delete(
        _participantsTableName,
        where: 'shared_investment_id = ?',
        whereArgs: [sharedInvestment.id],
      );

      // 插入新的参与者记录
      for (final participant in sharedInvestment.participants) {
        await txn.insert(_participantsTableName, {
          'id': participant.id,
          'shared_investment_id': participant.sharedInvestmentId,
          'user_id': participant.userId,
          'user_name': participant.userName,
          'investment_amount': participant.investmentAmount.toString(),
          'shares': participant.shares.toString(),
          'profit_loss': participant.profitLoss.toString(),
          'transaction_id': participant.transactionId,
        });
      }
    });
  }

  Future<void> deleteSharedInvestment(String id) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      // 删除参与者记录
      await txn.delete(
        _participantsTableName,
        where: 'shared_investment_id = ?',
        whereArgs: [id],
      );

      // 删除共享投资记录
      await txn.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  SharedInvestment _mapToSharedInvestment(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> participantMaps,
  ) {
    final participants = participantMaps.map((participantMap) {
      return SharedInvestmentParticipant(
        id: participantMap['id'],
        sharedInvestmentId: participantMap['shared_investment_id'],
        userId: participantMap['user_id'],
        userName: participantMap['user_name'],
        investmentAmount: Decimal.parse(participantMap['investment_amount']),
        shares: Decimal.parse(participantMap['shares']),
        profitLoss: Decimal.parse(participantMap['profit_loss']),
        transactionId: participantMap['transaction_id'],
      );
    }).toList();

    return SharedInvestment(
      id: map['id'],
      name: map['name'],
      stockCode: map['stock_code'],
      stockName: map['stock_name'],
      totalAmount: Decimal.parse(map['total_amount']),
      totalShares: Decimal.parse(map['total_shares']),
      initialPrice: Decimal.parse(map['initial_price']),
      currentPrice: map['current_price'] != null
          ? Decimal.parse(map['current_price'])
          : null,
      sellAmount: map['sell_amount'] != null
          ? Decimal.parse(map['sell_amount'])
          : null,
      createdDate: DateTime.parse(map['created_date']),
      status: SharedInvestmentStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => SharedInvestmentStatus.active,
      ),
      notes: map['notes'],
      participants: participants,
    );
  }
}
