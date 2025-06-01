import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:decimal/decimal.dart';

import '../../data/models/shared_investment.dart';
import '../../data/models/transaction.dart';
import '../../data/datasources/local/shared_investment_dao.dart';
import '../../data/repositories/shared_investment_repository.dart';
import 'user_provider.dart';
import 'transaction_provider.dart';

part 'shared_investment_provider.g.dart';

// Repository providers
@riverpod
SharedInvestmentDao sharedInvestmentDao(SharedInvestmentDaoRef ref) {
  return SharedInvestmentDao();
}

@riverpod
SharedInvestmentRepository sharedInvestmentRepository(SharedInvestmentRepositoryRef ref) {
  return SharedInvestmentRepository(ref.watch(sharedInvestmentDaoProvider));
}

// Shared investment notifier
@riverpod
class SharedInvestmentNotifier extends _$SharedInvestmentNotifier {
  @override
  Future<List<SharedInvestment>> build() async {
    final user = ref.watch(userProvider);
    if (user == null) return [];

    final repository = ref.watch(sharedInvestmentRepositoryProvider);
    return await repository.getSharedInvestmentsByUserId(user.id);
  }

  Future<void> createSharedInvestment({
    required String name,
    required String stockCode,
    required String stockName,
    required List<SharedInvestmentParticipant> participants,
    Decimal? sellAmount,
    String? notes,
  }) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);

    // 计算总投资和总持仓
    final totalAmount = participants.fold(
      Decimal.zero,
      (sum, p) => sum + p.investmentAmount,
    );
    final totalShares = participants.fold(
      Decimal.zero,
      (sum, p) => sum + p.shares,
    );

    final sharedInvestmentId = const Uuid().v4();
    final createdDate = DateTime.now();

    final sharedInvestment = SharedInvestment(
      id: sharedInvestmentId,
      name: name,
      stockCode: stockCode,
      stockName: stockName,
      totalAmount: totalAmount,
      totalShares: totalShares,
      initialPrice: totalShares > Decimal.zero ? Decimal.parse(((totalAmount / totalShares).toDouble()).toStringAsFixed(2)) : Decimal.zero,
      sellAmount: sellAmount,
      createdDate: createdDate,
      notes: notes,
      participants: participants.map((p) => p.copyWith(
        id: const Uuid().v4(),
        sharedInvestmentId: sharedInvestmentId,
      )).toList(),
    );

    // 创建共享投资记录
    await repository.createSharedInvestment(sharedInvestment);

    // 为每个参与者创建交易记录
    for (final participant in sharedInvestment.participants) {
      final unitPrice = participant.shares > Decimal.zero
          ? Decimal.parse(((participant.investmentAmount / participant.shares).toDouble()).toStringAsFixed(2))
          : Decimal.zero;

      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: participant.userId,
        date: createdDate,
        stockCode: stockCode,
        stockName: stockName,
        amount: participant.shares,
        unitPrice: unitPrice,
        profitLoss: participant.profitLoss,
        tags: ['共享投资'],
        notes: '共享投资：$name',
        sharedInvestmentId: sharedInvestmentId,
        createdAt: createdDate,
        updatedAt: createdDate,
      );

      await transactionRepository.addTransaction(transaction);
    }

    ref.invalidateSelf();
    // 刷新交易记录
    ref.invalidate(transactionNotifierProvider);
  }

  Future<void> updateSharedInvestment(SharedInvestment sharedInvestment) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    await repository.updateSharedInvestment(sharedInvestment);
    ref.invalidateSelf();
  }

  Future<void> deleteSharedInvestment(String id) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    await repository.deleteSharedInvestment(id);
    ref.invalidateSelf();
  }

  Future<void> updateCurrentPrice(String id, Decimal currentPrice) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    final sharedInvestment = await repository.getSharedInvestmentById(id);

    if (sharedInvestment != null) {
      final updatedSharedInvestment = sharedInvestment.copyWith(
        currentPrice: currentPrice,
      );
      await repository.updateSharedInvestment(updatedSharedInvestment);
      ref.invalidateSelf();
    }
  }

  Future<void> completeSharedInvestment(String id, Decimal sellAmount) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    final sharedInvestment = await repository.getSharedInvestmentById(id);

    if (sharedInvestment != null) {
      // 计算每个参与者的盈亏
      final totalShares = sharedInvestment.totalShares;
      final profitPerShare = totalShares > Decimal.zero
          ? Decimal.parse((((sellAmount - sharedInvestment.totalAmount) / totalShares).toDouble()).toStringAsFixed(4))
          : Decimal.zero;

      final updatedParticipants = sharedInvestment.participants.map((participant) {
        final profitLoss = Decimal.parse(((participant.shares * profitPerShare).toDouble()).toStringAsFixed(2));
        return participant.copyWith(profitLoss: profitLoss);
      }).toList();

      final updatedSharedInvestment = sharedInvestment.copyWith(
        sellAmount: sellAmount,
        status: SharedInvestmentStatus.completed,
        participants: updatedParticipants,
      );

      await repository.updateSharedInvestment(updatedSharedInvestment);
      ref.invalidateSelf();
    }
  }

  /// 完成共享投资（带自定义盈亏分配）
  Future<void> completeSharedInvestmentWithCustomProfitLoss(
    String id,
    Decimal? sellAmount,
    Map<String, Decimal> participantProfitLoss,
  ) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final sharedInvestment = await repository.getSharedInvestmentById(id);

    if (sharedInvestment != null) {
      // 更新参与者盈亏
      final updatedParticipants = sharedInvestment.participants.map((participant) {
        final profitLoss = participantProfitLoss[participant.id] ?? participant.profitLoss;
        return participant.copyWith(profitLoss: profitLoss);
      }).toList();

      final updatedSharedInvestment = sharedInvestment.copyWith(
        sellAmount: sellAmount ?? sharedInvestment.sellAmount,
        status: SharedInvestmentStatus.completed,
        participants: updatedParticipants,
      );

      await repository.updateSharedInvestment(updatedSharedInvestment);

      // 更新相关的交易记录
      for (final participant in updatedParticipants) {
        final transactions = await transactionRepository.getTransactionsBySharedInvestmentId(id);
        final userTransaction = transactions.where((t) => t.userId == participant.userId).firstOrNull;

        if (userTransaction != null) {
          final updatedTransaction = userTransaction.copyWith(
            profitLoss: participant.profitLoss,
            updatedAt: DateTime.now(),
          );
          await transactionRepository.updateTransaction(updatedTransaction);
        }
      }

      ref.invalidateSelf();
      ref.invalidate(transactionNotifierProvider);
    }
  }

  /// 取消共享投资
  Future<void> cancelSharedInvestment(String id, {String? reason}) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    await repository.cancelSharedInvestment(id, reason: reason);
    ref.invalidateSelf();
  }

  /// 更新共享投资状态
  Future<void> updateSharedInvestmentStatus(String id, SharedInvestmentStatus status) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    await repository.updateSharedInvestmentStatus(id, status);
    ref.invalidateSelf();
  }

  /// 更新参与者盈亏
  Future<void> updateParticipantProfitLoss(
    String sharedInvestmentId,
    String participantId,
    Decimal profitLoss,
  ) async {
    final repository = ref.read(sharedInvestmentRepositoryProvider);
    await repository.updateParticipantProfitLoss(sharedInvestmentId, participantId, profitLoss);
    ref.invalidateSelf();
  }
}

// Individual shared investment provider
@riverpod
Future<SharedInvestment?> sharedInvestment(SharedInvestmentRef ref, String id) async {
  final repository = ref.watch(sharedInvestmentRepositoryProvider);
  return await repository.getSharedInvestmentById(id);
}

// Shared investment stats provider
@riverpod
Future<Map<String, dynamic>> sharedInvestmentStats(SharedInvestmentStatsRef ref, String id) async {
  final repository = ref.watch(sharedInvestmentRepositoryProvider);
  return await repository.calculateSharedInvestmentStats(id);
}

// User stats in shared investment provider
@riverpod
Future<Map<String, dynamic>> userSharedInvestmentStats(
  UserSharedInvestmentStatsRef ref,
  String sharedInvestmentId,
  String userId,
) async {
  final repository = ref.watch(sharedInvestmentRepositoryProvider);
  return await repository.getUserStatsInSharedInvestment(sharedInvestmentId, userId);
}

// All shared investments provider (for admin purposes)
@riverpod
Future<List<SharedInvestment>> allSharedInvestments(AllSharedInvestmentsRef ref) async {
  final repository = ref.watch(sharedInvestmentRepositoryProvider);
  return await repository.getAllSharedInvestments();
}
