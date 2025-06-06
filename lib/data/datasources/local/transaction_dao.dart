import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:decimal/decimal.dart';

import '../../models/transaction.dart' as models;
import '../../database/database_helper.dart';

class TransactionDao {
  static const String _tableName = 'transactions';

  Future<String> createTransaction(models.Transaction transaction) async {
    final db = await DatabaseHelper.database;
    final id = transaction.id ?? const Uuid().v4();

    final transactionWithId = transaction.copyWith(
      id: id,
      createdAt: transaction.createdAt,
      updatedAt: DateTime.now(),
    );

    await db.insert(_tableName, {
      'id': transactionWithId.id,
      'user_id': transactionWithId.userId,
      'date': transactionWithId.date.toIso8601String(),
      'stock_code': transactionWithId.stockCode,
      'stock_name': transactionWithId.stockName,
      'amount': transactionWithId.amount.toString(),
      'unit_price': transactionWithId.unitPrice.toString(),
      'profit_loss': transactionWithId.profitLoss.toString(),
      'tags': jsonEncode(transactionWithId.tags),
      'notes': transactionWithId.notes,
      'shared_investment_id': transactionWithId.sharedInvestmentId,
      'created_at': transactionWithId.createdAt.toIso8601String(),
      'updated_at': transactionWithId.updatedAt?.toIso8601String(),
      'is_deleted': transactionWithId.isDeleted ? 1 : 0,
    });

    return id;
  }

  Future<models.Transaction?> getTransactionById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToTransaction(maps.first);
  }

  Future<List<models.Transaction>> getTransactionsByUserId(String userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'user_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  Future<List<models.Transaction>> getTransactionsByStockCode(String stockCode) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'stock_code = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [stockCode],
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  Future<List<models.Transaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'user_id = ? AND date >= ? AND date <= ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'is_deleted IS NULL OR is_deleted = 0',
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  // 获取所有交易记录（包括已删除的，用于同步）
  Future<List<models.Transaction>> getAllTransactionsForSync(String userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {
        'user_id': transaction.userId,
        'date': transaction.date.toIso8601String(),
        'stock_code': transaction.stockCode,
        'stock_name': transaction.stockName,
        'amount': transaction.amount.toString(),
        'unit_price': transaction.unitPrice.toString(),
        'profit_loss': transaction.profitLoss.toString(),
        'tags': jsonEncode(transaction.tags),
        'notes': transaction.notes,
        'shared_investment_id': transaction.sharedInvestmentId,
        'updated_at': DateTime.now().toIso8601String(),
        'is_deleted': transaction.isDeleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  models.Transaction _mapToTransaction(Map<String, dynamic> map) {
    return models.Transaction(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      stockCode: map['stock_code'],
      stockName: map['stock_name'],
      amount: Decimal.parse(_safeToString(map['amount'])),
      unitPrice: Decimal.parse(_safeToString(map['unit_price'])),
      profitLoss: Decimal.parse(_safeToString(map['profit_loss'])),
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      notes: map['notes'],
      sharedInvestmentId: map['shared_investment_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  // 安全地将值转换为字符串
  String _safeToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }
}
