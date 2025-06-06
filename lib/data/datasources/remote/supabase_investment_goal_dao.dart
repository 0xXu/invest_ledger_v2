import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:decimal/decimal.dart';

import '../../models/investment_goal.dart' as models;
import '../../../core/config/supabase_config.dart';

class SupabaseInvestmentGoalDao {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _tableName = 'investment_goals';
  
  // 获取用户的所有投资目标
  Future<List<models.InvestmentGoal>> getGoalsByUserId(String userId) async {
    try {
      debugPrint('🔍 尝试从 Supabase 获取投资目标，用户ID: $userId');
      
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      debugPrint('✅ Supabase 响应成功，目标数量: ${(response as List).length}');

      return (response as List)
          .map((json) => models.InvestmentGoal.fromJson(_supabaseJsonToGoal(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Supabase 请求失败: $e');
      throw Exception('获取投资目标失败: $e');
    }
  }
  
  // 创建投资目标
  Future<models.InvestmentGoal> createGoal(models.InvestmentGoal goal) async {
    try {
      final data = _goalToSupabaseJson(goal);
      final response = await _client
          .from(_tableName)
          .insert(data)
          .select()
          .single();
      
      return models.InvestmentGoal.fromJson(_supabaseJsonToGoal(response));
    } catch (e) {
      throw Exception('创建投资目标失败: $e');
    }
  }
  
  // 更新投资目标
  Future<models.InvestmentGoal> updateGoal(models.InvestmentGoal goal) async {
    try {
      final data = _goalToSupabaseJson(goal);
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', goal.id!)
          .select()
          .single();
      
      return models.InvestmentGoal.fromJson(_supabaseJsonToGoal(response));
    } catch (e) {
      throw Exception('更新投资目标失败: $e');
    }
  }
  
  // 软删除投资目标
  Future<void> deleteGoal(String id) async {
    try {
      await _client
          .from(_tableName)
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('删除投资目标失败: $e');
    }
  }
  
  // 获取指定时间后修改的记录（用于增量同步）
  Future<List<models.InvestmentGoal>> getModifiedSince(
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
          .map((json) => models.InvestmentGoal.fromJson(_supabaseJsonToGoal(json)))
          .toList();
    } catch (e) {
      throw Exception('获取修改记录失败: $e');
    }
  }
  
  // 批量同步投资目标
  Future<List<models.InvestmentGoal>> batchSync(
    List<models.InvestmentGoal> goals,
  ) async {
    try {
      final data = goals
          .map(_goalToSupabaseJson)
          .toList();
      
      final response = await _client
          .from(_tableName)
          .upsert(data)
          .select();
      
      return (response as List)
          .map((json) => models.InvestmentGoal.fromJson(_supabaseJsonToGoal(json)))
          .toList();
    } catch (e) {
      throw Exception('批量同步失败: $e');
    }
  }
  
  // 转换为 Supabase JSON 格式
  Map<String, dynamic> _goalToSupabaseJson(models.InvestmentGoal goal) {
    return {
      if (goal.id != null) 'id': goal.id,
      'user_id': goal.userId,
      'type': goal.type.name,
      'period': goal.period.name,
      'year': goal.year,
      'month': goal.month,
      'target_amount': goal.targetAmount.toString(),
      'description': goal.description,
      'created_at': goal.createdAt.toIso8601String(),
      'updated_at': goal.updatedAt?.toIso8601String(),
      'is_deleted': goal.isDeleted,
    };
  }
  
  // 从 Supabase JSON 转换
  Map<String, dynamic> _supabaseJsonToGoal(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'userId': json['user_id'],
      'type': json['type'],
      'period': json['period'],
      'year': json['year'],
      'month': json['month'],
      'targetAmount': _safeToString(json['target_amount']),
      'description': json['description'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
      'isDeleted': json['is_deleted'] ?? false,
    };
  }

  // 安全地将值转换为字符串
  String _safeToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }
}
