import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status.freezed.dart';

@freezed
class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    @Default(false) bool isOnline,
    @Default(false) bool isSyncing,
    @Default(SyncState.idle) SyncState state,
    DateTime? lastSyncTime,
    String? errorMessage,
    @Default(0) int pendingChanges,
  }) = _SyncStatus;
}

enum SyncState {
  idle,
  syncing,
  success,
  error,
  conflict,
}

@freezed
class SyncableEntity with _$SyncableEntity {
  const factory SyncableEntity({
    required String id,
    required String tableName,
    required Map<String, dynamic> data,
    required SyncAction action,
    required DateTime timestamp,
    @Default(false) bool isSynced,
    String? conflictData,
  }) = _SyncableEntity;
}

enum SyncAction {
  create,
  update,
  delete,
}
