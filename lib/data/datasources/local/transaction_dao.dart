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
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  Future<List<models.Transaction>> getTransactionsByStockCode(String stockCode) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      _tableName,
      where: 'stock_code = ?',
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
      where: 'user_id = ? AND date >= ? AND date <= ?',
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
    final maps = await db.query(_tableName, orderBy: 'date DESC');

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
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      _tableName,
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
      amount: Decimal.parse(map['amount']),
      unitPrice: Decimal.parse(map['unit_price']),
      profitLoss: Decimal.parse(map['profit_loss']),
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      notes: map['notes'],
      sharedInvestmentId: map['shared_investment_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}
