import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../../data/datasources/local/transaction_dao.dart';
import '../../data/datasources/remote/supabase_transaction_dao.dart';
import '../../data/models/transaction.dart' as models;
import 'connectivity_service.dart';
import 'sync_status.dart';

class SyncManager {
  final TransactionDao _localTransactionDao;
  final SupabaseTransactionDao _remoteTransactionDao;
  final ConnectivityService _connectivityService;
  
  late StreamController<SyncStatus> _syncStatusController;
  SyncStatus _currentStatus = const SyncStatus();
  
  SyncManager({
    required TransactionDao localTransactionDao,
    required SupabaseTransactionDao remoteTransactionDao,
    required ConnectivityService connectivityService,
  }) : _localTransactionDao = localTransactionDao,
       _remoteTransactionDao = remoteTransactionDao,
       _connectivityService = connectivityService {
    _syncStatusController = StreamController<SyncStatus>.broadcast();
    _initSync();
  }
  
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  SyncStatus get currentStatus => _currentStatus;
  
  void _initSync() {
    // 监听网络状态变化
    _connectivityService.connectionStream.listen((isConnected) {
      _updateStatus(_currentStatus.copyWith(isOnline: isConnected));
      if (isConnected && SupabaseConfig.isLoggedIn) {
        // 网络恢复时自动同步
        _autoSync();
      }
    });
  }
  
  // 手动同步
  Future<void> manualSync() async {
    if (!_connectivityService.isConnected) {
      throw Exception('网络连接不可用');
    }
    
    if (!SupabaseConfig.isLoggedIn) {
      throw Exception('用户未登录');
    }
    
    await _performSync();
  }
  
  // 自动同步（静默）
  Future<void> _autoSync() async {
    try {
      if (_currentStatus.isSyncing) return;
      await _performSync();
    } catch (e) {
      // 自动同步失败时不抛出异常，只更新状态
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
        isSyncing: false,
      ));
    }
  }
  
  // 执行同步
  Future<void> _performSync() async {
    _updateStatus(_currentStatus.copyWith(
      isSyncing: true,
      state: SyncState.syncing,
      errorMessage: null,
    ));
    
    try {
      final userId = SupabaseConfig.currentUser!.id;
      
      // 1. 获取本地未同步的数据
      final localTransactions = await _localTransactionDao.getTransactionsByUserId(userId);
      final unsyncedTransactions = localTransactions.where((t) => 
        t.updatedAt?.isAfter(_getLastSyncTime()) ?? true
      ).toList();
      
      // 2. 推送本地更改到远程
      if (unsyncedTransactions.isNotEmpty) {
        await _remoteTransactionDao.batchSync(unsyncedTransactions);
      }
      
      // 3. 拉取远程更改
      final remoteTransactions = await _remoteTransactionDao.getModifiedSince(
        userId, 
        _getLastSyncTime(),
      );
      
      // 4. 合并远程数据到本地
      for (final remoteTransaction in remoteTransactions) {
        await _mergeTransaction(remoteTransaction);
      }
      
      // 5. 更新同步时间
      await _updateLastSyncTime();
      
      _updateStatus(_currentStatus.copyWith(
        isSyncing: false,
        state: SyncState.success,
        lastSyncTime: DateTime.now(),
        pendingChanges: 0,
      ));
      
    } catch (e) {
      _updateStatus(_currentStatus.copyWith(
        isSyncing: false,
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }
  
  // 合并远程交易记录到本地
  Future<void> _mergeTransaction(models.Transaction remoteTransaction) async {
    final localTransaction = await _localTransactionDao.getTransactionById(
      remoteTransaction.id!,
    );
    
    if (localTransaction == null) {
      // 本地不存在，直接插入
      await _localTransactionDao.createTransaction(remoteTransaction);
    } else {
      // 检查冲突
      if (_hasConflict(localTransaction, remoteTransaction)) {
        // 处理冲突：这里简单地使用远程数据覆盖本地数据
        // 实际应用中可能需要更复杂的冲突解决策略
        await _localTransactionDao.updateTransaction(remoteTransaction);
        
        _updateStatus(_currentStatus.copyWith(
          state: SyncState.conflict,
        ));
      } else {
        // 无冲突，更新本地数据
        await _localTransactionDao.updateTransaction(remoteTransaction);
      }
    }
  }
  
  // 检查是否有冲突
  bool _hasConflict(models.Transaction local, models.Transaction remote) {
    // 简单的冲突检测：比较更新时间
    final localUpdated = local.updatedAt ?? local.createdAt;
    final remoteUpdated = remote.updatedAt ?? remote.createdAt;
    
    return localUpdated.isAfter(remoteUpdated) && 
           !_isSameData(local, remote);
  }
  
  // 检查数据是否相同
  bool _isSameData(models.Transaction local, models.Transaction remote) {
    return local.stockCode == remote.stockCode &&
           local.stockName == remote.stockName &&
           local.amount == remote.amount &&
           local.unitPrice == remote.unitPrice &&
           local.profitLoss == remote.profitLoss;
  }
  
  // 获取上次同步时间
  DateTime _getLastSyncTime() {
    // 从 SharedPreferences 获取，默认为很久以前
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  
  // 更新同步时间
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
  }
  
  // 更新同步状态
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }
  
  void dispose() {
    _syncStatusController.close();
  }
}

// Riverpod providers
final syncManagerProvider = Provider<SyncManager>((ref) {
  final localDao = ref.watch(transactionDaoProvider);
  final remoteDao = SupabaseTransactionDao();
  final connectivity = ref.watch(connectivityServiceProvider);
  
  final manager = SyncManager(
    localTransactionDao: localDao,
    remoteTransactionDao: remoteDao,
    connectivityService: connectivity,
  );
  
  ref.onDispose(() => manager.dispose());
  return manager;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final manager = ref.watch(syncManagerProvider);
  return manager.syncStatusStream;
});

// 本地 DAO provider（需要在相应文件中定义）
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao();
});
