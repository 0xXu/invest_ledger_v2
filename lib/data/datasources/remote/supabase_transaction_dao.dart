import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/transaction.dart' as models;

class SupabaseTransactionDao {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _tableName = 'transactions';
  
  // 获取用户的所有交易记录
  Future<List<models.Transaction>> getTransactionsByUserId(String userId) async {
    try {
      debugPrint('🔍 尝试从 Supabase 获取交易记录，用户ID: $userId');
      debugPrint('🔍 表名: $_tableName');
      debugPrint('🔍 当前用户: ${SupabaseConfig.currentUser?.id}');

      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      debugPrint('✅ Supabase 响应成功，记录数量: ${(response as List).length}');

      return (response as List)
          .map((json) => models.Transaction.fromJson(_supabaseJsonToTransaction(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Supabase 请求失败: $e');
      debugPrint('❌ 错误类型: ${e.runtimeType}');
      throw Exception('获取交易记录失败: $e');
    }
  }
  
  // 创建交易记录
  Future<models.Transaction> createTransaction(models.Transaction transaction) async {
    try {
      final data = _transactionToSupabaseJson(transaction);
      final response = await _client
          .from(_tableName)
          .insert(data)
          .select()
          .single();
      
      return models.Transaction.fromJson(_supabaseJsonToTransaction(response));
    } catch (e) {
      throw Exception('创建交易记录失败: $e');
    }
  }
  
  // 更新交易记录
  Future<models.Transaction> updateTransaction(models.Transaction transaction) async {
    try {
      final data = _transactionToSupabaseJson(transaction);
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', transaction.id!)
          .select()
          .single();
      
      return models.Transaction.fromJson(_supabaseJsonToTransaction(response));
    } catch (e) {
      throw Exception('更新交易记录失败: $e');
    }
  }
  
  // 软删除交易记录
  Future<void> deleteTransaction(String id) async {
    try {
      await _client
          .from(_tableName)
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('删除交易记录失败: $e');
    }
  }
  
  // 获取指定时间后修改的记录（用于增量同步）
  Future<List<models.Transaction>> getModifiedSince(
    String userId, 
    DateTime since,
  ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('updated_at', since.toIso8601String())
          .order('updated_at', ascending: false);
      
      return (response as List)
          .map((json) => models.Transaction.fromJson(_supabaseJsonToTransaction(json)))
          .toList();
    } catch (e) {
      throw Exception('获取修改记录失败: $e');
    }
  }
  
  // 批量同步交易记录
  Future<List<models.Transaction>> batchSync(
    List<models.Transaction> transactions,
  ) async {
    try {
      final data = transactions
          .map(_transactionToSupabaseJson)
          .toList();
      
      final response = await _client
          .from(_tableName)
          .upsert(data)
          .select();
      
      return (response as List)
          .map((json) => models.Transaction.fromJson(_supabaseJsonToTransaction(json)))
          .toList();
    } catch (e) {
      throw Exception('批量同步失败: $e');
    }
  }
  
  // 将 Supabase JSON 格式转换为 Transaction 模型格式
  Map<String, dynamic> _supabaseJsonToTransaction(Map<String, dynamic> supabaseJson) {
    return {
      'id': supabaseJson['id'],
      'userId': supabaseJson['user_id'],
      'date': supabaseJson['date'],
      'stockCode': supabaseJson['stock_code'],
      'stockName': supabaseJson['stock_name'],
      'amount': _safeToString(supabaseJson['amount']),
      'unitPrice': _safeToString(supabaseJson['unit_price']),
      'profitLoss': _safeToString(supabaseJson['profit_loss']),
      'tags': supabaseJson['tags'] ?? [],
      'notes': supabaseJson['notes'],
      'createdAt': supabaseJson['created_at'],
      'updatedAt': supabaseJson['updated_at'],
      'isDeleted': supabaseJson['is_deleted'] ?? false,
    };
  }

  // 安全地将值转换为字符串
  String _safeToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  // 将 Transaction 模型转换为 Supabase JSON 格式
  Map<String, dynamic> _transactionToSupabaseJson(models.Transaction transaction) {
    return {
      'id': transaction.id,
      'user_id': transaction.userId,
      'date': transaction.date.toIso8601String(),
      'stock_code': transaction.stockCode,
      'stock_name': transaction.stockName,
      'amount': transaction.amount.toString(),
      'unit_price': transaction.unitPrice.toString(),
      'profit_loss': transaction.profitLoss.toString(),
      'tags': transaction.tags,
      'notes': transaction.notes,
      'created_at': transaction.createdAt.toIso8601String(),
      'updated_at': transaction.updatedAt?.toIso8601String(),
      'is_deleted': transaction.isDeleted,
    };
  }
}
