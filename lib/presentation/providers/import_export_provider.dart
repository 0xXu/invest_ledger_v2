import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/import_export_service.dart';
import '../../data/models/import_result.dart';
import '../../core/auth/auth_service.dart';
import '../../core/sync/sync_manager.dart';
import 'transaction_provider.dart';
import 'shared_investment_provider.dart';
import 'investment_goal_provider.dart';

part 'import_export_provider.g.dart';

// Import/Export service provider
@riverpod
ImportExportService importExportService(ImportExportServiceRef ref) {
  return ImportExportService(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    sharedInvestmentRepository: ref.watch(sharedInvestmentRepositoryProvider),
    investmentGoalRepository: ref.watch(investmentGoalRepositoryProvider),
  );
}

// Import/Export notifier
@riverpod
class ImportExportNotifier extends _$ImportExportNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// 导出交易记录为CSV
  Future<String?> exportTransactionsToCSV() async {
    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      throw Exception('用户未登录');
    }

    state = const AsyncValue.loading();

    try {
      final service = ref.read(importExportServiceProvider);
      final result = await service.exportTransactionsToCSV(authState.user!.id);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 从CSV导入交易记录
  Future<int> importTransactionsFromCSV() async {
    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      throw Exception('用户未登录');
    }

    state = const AsyncValue.loading();

    try {
      final service = ref.read(importExportServiceProvider);
      final result = await service.importTransactionsFromCSV(authState.user!.id);

      // 刷新交易记录
      ref.invalidate(transactionNotifierProvider);

      // 自动触发同步
      _triggerAutoSync();

      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 从TXT导入交易记录
  Future<TxtImportResult> importTransactionsFromTXT() async {
    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      throw Exception('用户未登录');
    }

    state = const AsyncValue.loading();

    try {
      final service = ref.read(importExportServiceProvider);
      final result = await service.importTransactionsFromTXT(authState.user!.id);

      // 刷新交易记录
      ref.invalidate(transactionNotifierProvider);

      // 自动触发同步
      _triggerAutoSync();

      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 导出完整数据备份
  Future<String?> exportFullBackup() async {
    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      throw Exception('用户未登录');
    }

    state = const AsyncValue.loading();

    try {
      final service = ref.read(importExportServiceProvider);
      final result = await service.exportFullBackup(authState.user!.id);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 从备份文件恢复数据
  Future<Map<String, int>> importFullBackup() async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(importExportServiceProvider);
      final result = await service.importFullBackup();

      // 刷新所有数据
      ref.invalidate(transactionNotifierProvider);
      ref.invalidate(sharedInvestmentNotifierProvider);
      ref.invalidate(investmentGoalNotifierProvider);

      // 自动触发同步
      _triggerAutoSync();

      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 触发自动同步
  void _triggerAutoSync() {
    try {
      final syncManager = ref.read(syncManagerProvider);
      // 异步执行同步，不阻塞当前操作
      Future.microtask(() async {
        try {
          await syncManager.manualSync();
          // 同步完成后刷新所有相关数据
          ref.invalidate(transactionNotifierProvider);
          ref.invalidate(sharedInvestmentNotifierProvider);
          ref.invalidate(investmentGoalNotifierProvider);
        } catch (e) {
          // 同步失败时不影响用户操作，只是静默处理
          // 可以在这里记录日志或显示非阻塞性提示
        }
      });
    } catch (e) {
      // 如果获取syncManager失败，也不影响用户操作
    }
  }

  /// 执行自动备份
  Future<String> autoBackup() async {
    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      throw Exception('用户未登录');
    }

    try {
      final service = ref.read(importExportServiceProvider);
      return await service.autoBackup(authState.user!.id);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取应用数据目录
  Future<String> getAppDataDirectory() async {
    final service = ref.read(importExportServiceProvider);
    return await service.getAppDataDirectory();
  }
}

// Auto backup provider (for scheduled backups)
@riverpod
class AutoBackupNotifier extends _$AutoBackupNotifier {
  @override
  DateTime? build() {
    return null; // Last backup time
  }

  /// 检查是否需要自动备份
  bool shouldAutoBackup() {
    final lastBackup = state;
    if (lastBackup == null) return true;

    final now = DateTime.now();
    final daysSinceLastBackup = now.difference(lastBackup).inDays;

    return daysSinceLastBackup >= 7; // 每周自动备份一次
  }

  /// 执行自动备份并更新时间
  Future<String?> performAutoBackup() async {
    if (!shouldAutoBackup()) return null;

    try {
      final importExportNotifier = ref.read(importExportNotifierProvider.notifier);
      final backupPath = await importExportNotifier.autoBackup();

      state = DateTime.now();
      return backupPath;
    } catch (e) {
      // 自动备份失败不影响应用正常使用
      return null;
    }
  }

  /// 手动设置最后备份时间
  void setLastBackupTime(DateTime time) {
    state = time;
  }
}
