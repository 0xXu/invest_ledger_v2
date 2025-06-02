import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_metadata.freezed.dart';
part 'sync_metadata.g.dart';

/// 同步元数据，用于跟踪数据的同步状态
@freezed
class SyncMetadata with _$SyncMetadata {
  const factory SyncMetadata({
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
    @Default(false) bool hasConflict,
    DateTime? lastSyncedAt,
    DateTime? lastModifiedAt,
    String? syncVersion,
    String? deviceId,
    Map<String, dynamic>? conflictData,
  }) = _SyncMetadata;

  factory SyncMetadata.fromJson(Map<String, dynamic> json) =>
      _$SyncMetadataFromJson(json);
}

/// 可同步的实体接口
mixin SyncableEntity {
  String get id;
  SyncMetadata get syncMetadata;
  DateTime get createdAt;
  DateTime? get updatedAt;
  
  /// 创建带有同步元数据的副本
  SyncableEntity copyWithSyncMetadata(SyncMetadata syncMetadata);
  
  /// 标记为已同步
  SyncableEntity markAsSynced() {
    return copyWithSyncMetadata(
      syncMetadata.copyWith(
        isSynced: true,
        lastSyncedAt: DateTime.now(),
        hasConflict: false,
      ),
    );
  }
  
  /// 标记为需要同步
  SyncableEntity markAsNeedSync() {
    return copyWithSyncMetadata(
      syncMetadata.copyWith(
        isSynced: false,
        lastModifiedAt: DateTime.now(),
      ),
    );
  }
  
  /// 标记为已删除
  SyncableEntity markAsDeleted() {
    return copyWithSyncMetadata(
      syncMetadata.copyWith(
        isDeleted: true,
        isSynced: false,
        lastModifiedAt: DateTime.now(),
      ),
    );
  }
  
  /// 标记为有冲突
  SyncableEntity markAsConflicted(Map<String, dynamic> conflictData) {
    return copyWithSyncMetadata(
      syncMetadata.copyWith(
        hasConflict: true,
        conflictData: conflictData,
      ),
    );
  }
}
