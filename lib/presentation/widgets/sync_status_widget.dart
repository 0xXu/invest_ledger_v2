import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_manager.dart';
import '../../core/sync/sync_status.dart';
import '../../core/config/supabase_config.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isLoggedIn) {
      return const SizedBox.shrink(); // 未登录时不显示
    }

    final syncStatusAsync = ref.watch(syncStatusProvider);
    
    return syncStatusAsync.when(
      data: (status) => _buildStatusWidget(context, ref, status),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusWidget(BuildContext context, WidgetRef ref, SyncStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(status),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status.isSyncing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_getStatusColor(status)),
              ),
            ),
          ],
          if (!status.isSyncing && status.isOnline) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _handleManualSync(context, ref),
              child: Icon(
                Icons.refresh,
                size: 16,
                color: _getStatusColor(status),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    IconData icon;
    
    if (!status.isOnline) {
      icon = Icons.cloud_off;
    } else if (status.isSyncing) {
      icon = Icons.cloud_sync;
    } else {
      switch (status.state) {
        case SyncState.success:
          icon = Icons.cloud_done;
          break;
        case SyncState.error:
          icon = Icons.cloud_off;
          break;
        case SyncState.conflict:
          icon = Icons.warning;
          break;
        default:
          icon = Icons.cloud;
      }
    }
    
    return Icon(
      icon,
      size: 16,
      color: _getStatusColor(status),
    );
  }

  String _getStatusText(SyncStatus status) {
    if (!status.isOnline) {
      return '离线';
    }
    
    if (status.isSyncing) {
      return '同步中...';
    }
    
    switch (status.state) {
      case SyncState.success:
        if (status.lastSyncTime != null) {
          final diff = DateTime.now().difference(status.lastSyncTime!);
          if (diff.inMinutes < 1) {
            return '刚刚同步';
          } else if (diff.inHours < 1) {
            return '${diff.inMinutes}分钟前';
          } else if (diff.inDays < 1) {
            return '${diff.inHours}小时前';
          } else {
            return '${diff.inDays}天前';
          }
        }
        return '已同步';
      case SyncState.error:
        return '同步失败';
      case SyncState.conflict:
        return '有冲突';
      default:
        return '未同步';
    }
  }

  Color _getStatusColor(SyncStatus status) {
    if (!status.isOnline) {
      return Colors.grey;
    }
    
    if (status.isSyncing) {
      return Colors.blue;
    }
    
    switch (status.state) {
      case SyncState.success:
        return Colors.green;
      case SyncState.error:
        return Colors.red;
      case SyncState.conflict:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleManualSync(BuildContext context, WidgetRef ref) async {
    try {
      final syncManager = ref.read(syncManagerProvider);
      await syncManager.manualSync();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步完成')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    }
  }
}
