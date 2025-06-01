import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../models/ai_analysis_result.dart';
import '../../database/database_helper.dart';

class AISuggestionDao {
  static const String _tableName = 'ai_suggestions';

  Future<String> createSuggestion(AISuggestion suggestion) async {
    final db = await DatabaseHelper.database;
    final id = suggestion.id ?? const Uuid().v4();

    await db.insert(_tableName, {
      'id': id,
      'user_id': suggestion.userId,
      'analysis_data': jsonEncode(suggestion.analysis.toJson()),
      'created_at': suggestion.createdAt.toIso8601String(),
      'executed_at': suggestion.executedAt?.toIso8601String(),
      'transaction_id': suggestion.transactionId,
      'status': suggestion.status.name,
      'user_notes': suggestion.userNotes,
    });

    return id;
  }

  Future<List<AISuggestion>> getSuggestionsByUser(String userId) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToSuggestion(map)).toList();
  }

  Future<AISuggestion?> getSuggestionById(String id) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToSuggestion(maps.first);
  }

  Future<void> updateSuggestion(AISuggestion suggestion) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {
        'executed_at': suggestion.executedAt?.toIso8601String(),
        'transaction_id': suggestion.transactionId,
        'status': suggestion.status.name,
        'user_notes': suggestion.userNotes,
      },
      where: 'id = ?',
      whereArgs: [suggestion.id],
    );
  }

  Future<void> deleteSuggestion(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AISuggestion>> getPendingSuggestions(String userId) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, AISuggestionStatus.pending.name],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToSuggestion(map)).toList();
  }

  Future<List<AISuggestion>> getSuggestionsByStock(String userId, String stockCode) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    // 过滤出指定股票的建议
    return maps
        .map((map) => _mapToSuggestion(map))
        .where((suggestion) => suggestion.analysis.stockCode == stockCode)
        .toList();
  }

  AISuggestion _mapToSuggestion(Map<String, dynamic> map) {
    final analysisData = jsonDecode(map['analysis_data']) as Map<String, dynamic>;
    
    return AISuggestion(
      id: map['id'],
      userId: map['user_id'],
      analysis: AIAnalysisResult.fromJson(analysisData),
      createdAt: DateTime.parse(map['created_at']),
      executedAt: map['executed_at'] != null 
          ? DateTime.parse(map['executed_at']) 
          : null,
      transactionId: map['transaction_id'],
      status: AISuggestionStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => AISuggestionStatus.pending,
      ),
      userNotes: map['user_notes'],
    );
  }
}
