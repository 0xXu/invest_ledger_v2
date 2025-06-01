import 'package:decimal/decimal.dart';

import '../models/shared_investment.dart';
import '../datasources/local/shared_investment_dao.dart';

class SharedInvestmentRepository {
  final SharedInvestmentDao _dao;

  SharedInvestmentRepository(this._dao);

  Future<String> createSharedInvestment(SharedInvestment sharedInvestment) async {
    return await _dao.createSharedInvestment(sharedInvestment);
  }

  Future<SharedInvestment?> getSharedInvestmentById(String id) async {
    return await _dao.getSharedInvestmentById(id);
  }

  Future<List<SharedInvestment>> getAllSharedInvestments() async {
    return await _dao.getAllSharedInvestments();
  }

  Future<List<SharedInvestment>> getSharedInvestmentsByUserId(String userId) async {
    return await _dao.getSharedInvestmentsByUserId(userId);
  }

  Future<void> updateSharedInvestment(SharedInvestment sharedInvestment) async {
    await _dao.updateSharedInvestment(sharedInvestment);
  }

  Future<void> deleteSharedInvestment(String id) async {
    await _dao.deleteSharedInvestment(id);
  }

  /// 更新共享投资状态
  Future<void> updateSharedInvestmentStatus(String id, SharedInvestmentStatus status) async {
    final sharedInvestment = await getSharedInvestmentById(id);
    if (sharedInvestment != null) {
      final updatedInvestment = sharedInvestment.copyWith(status: status);
      await updateSharedInvestment(updatedInvestment);
    }
  }

  /// 标记共享投资为完成
  Future<void> markAsCompleted(String id, {Decimal? finalSellAmount}) async {
    final sharedInvestment = await getSharedInvestmentById(id);
    if (sharedInvestment != null) {
      final updatedInvestment = sharedInvestment.copyWith(
        status: SharedInvestmentStatus.completed,
        sellAmount: finalSellAmount ?? sharedInvestment.sellAmount,
      );
      await updateSharedInvestment(updatedInvestment);
    }
  }

  /// 取消共享投资
  Future<void> cancelSharedInvestment(String id, {String? reason}) async {
    final sharedInvestment = await getSharedInvestmentById(id);
    if (sharedInvestment != null) {
      final updatedNotes = reason != null
          ? '${sharedInvestment.notes ?? ''}\n取消原因: $reason'.trim()
          : sharedInvestment.notes;

      final updatedInvestment = sharedInvestment.copyWith(
        status: SharedInvestmentStatus.cancelled,
        notes: updatedNotes,
      );
      await updateSharedInvestment(updatedInvestment);
    }
  }

  /// 更新参与者盈亏
  Future<void> updateParticipantProfitLoss(
    String sharedInvestmentId,
    String participantId,
    Decimal profitLoss,
  ) async {
    final sharedInvestment = await getSharedInvestmentById(sharedInvestmentId);
    if (sharedInvestment != null) {
      final updatedParticipants = sharedInvestment.participants.map((participant) {
        if (participant.id == participantId) {
          return participant.copyWith(profitLoss: profitLoss);
        }
        return participant;
      }).toList();

      final updatedInvestment = sharedInvestment.copyWith(participants: updatedParticipants);
      await updateSharedInvestment(updatedInvestment);
    }
  }

  /// 计算共享投资的总盈亏
  Future<Map<String, dynamic>> calculateSharedInvestmentStats(String sharedInvestmentId) async {
    final sharedInvestment = await getSharedInvestmentById(sharedInvestmentId);
    if (sharedInvestment == null) {
      return {
        'totalProfit': 0.0,
        'totalLoss': 0.0,
        'netProfit': 0.0,
        'roi': 0.0,
        'participantCount': 0,
      };
    }

    double totalProfit = 0.0;
    double totalLoss = 0.0;

    for (final participant in sharedInvestment.participants) {
      final profitLoss = participant.profitLoss.toDouble();
      if (profitLoss > 0) {
        totalProfit += profitLoss;
      } else {
        totalLoss += profitLoss.abs();
      }
    }

    final netProfit = totalProfit - totalLoss;
    final totalInvestment = sharedInvestment.totalAmount.toDouble();
    final roi = totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0.0;

    return {
      'totalProfit': totalProfit,
      'totalLoss': totalLoss,
      'netProfit': netProfit,
      'roi': roi,
      'participantCount': sharedInvestment.participants.length,
      'totalInvestment': totalInvestment,
      'currentValue': sharedInvestment.sellAmount?.toDouble() ?? totalInvestment,
    };
  }

  /// 获取用户在特定共享投资中的统计信息
  Future<Map<String, dynamic>> getUserStatsInSharedInvestment(
    String sharedInvestmentId,
    String userId,
  ) async {
    final sharedInvestment = await getSharedInvestmentById(sharedInvestmentId);
    if (sharedInvestment == null) {
      return {
        'investmentAmount': 0.0,
        'shares': 0.0,
        'profitLoss': 0.0,
        'profitLossPercentage': 0.0,
        'sharePercentage': 0.0,
      };
    }

    final participant = sharedInvestment.participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => SharedInvestmentParticipant(
        id: '',
        sharedInvestmentId: sharedInvestmentId,
        userId: userId,
        userName: '',
        investmentAmount: Decimal.zero,
        shares: Decimal.zero,
        profitLoss: Decimal.zero,
      ),
    );

    final investmentAmount = participant.investmentAmount.toDouble();
    final profitLoss = participant.profitLoss.toDouble();
    final profitLossPercentage = investmentAmount > 0
        ? (profitLoss / investmentAmount) * 100
        : 0.0;

    final totalShares = sharedInvestment.totalShares.toDouble();
    final userShares = participant.shares.toDouble();
    final sharePercentage = totalShares > 0
        ? (userShares / totalShares) * 100
        : 0.0;

    return {
      'investmentAmount': investmentAmount,
      'shares': userShares,
      'profitLoss': profitLoss,
      'profitLossPercentage': profitLossPercentage,
      'sharePercentage': sharePercentage,
    };
  }
}
