import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_manager.dart';
import '../../core/sync/sync_status.dart';
import '../../core/config/supabase_config.dart';

class SyncStatusWidget extends ConsumerStatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  ConsumerState<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends ConsumerState<SyncStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _refreshController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pressAnimation;
  late Animation<double> _rotationAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final canSync = !status.isSyncing && status.isOnline;

    return MouseRegion(
      onEnter: canSync ? (_) => _handleHoverEnter() : null,
      onExit: canSync ? (_) => _handleHoverExit() : null,
      child: GestureDetector(
        onTapDown: canSync ? (_) => _handleTapDown() : null,
        onTapUp: canSync ? (_) => _handleTapUp() : null,
        onTapCancel: canSync ? _handleTapCancel : null,
        onTap: canSync ? () => _handleManualSync(context, ref) : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _pressAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * _pressAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: _isHovered && canSync ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: _isHovered && canSync ? 0.5 : 0.3),
                    width: _isHovered && canSync ? 1.5 : 1,
                  ),
                  boxShadow: _isHovered && canSync
                      ? [
                          BoxShadow(
                            color: _getStatusColor(status).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
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
                    if (canSync) ...[
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * 2 * 3.14159,
                            child: Icon(
                              Icons.refresh,
                              size: 16,
                              color: _getStatusColor(status),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleHoverEnter() {
    if (!_isHovered) {
      setState(() {
        _isHovered = true;
      });
      _hoverController.forward();
    }
  }

  void _handleHoverExit() {
    if (_isHovered) {
      setState(() {
        _isHovered = false;
      });
      _hoverController.reverse();
    }
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
  }

  void _handleTapUp() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _pressController.reverse();
    }
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
    // 开始旋转动画
    _refreshController.repeat();

    try {
      final syncManager = ref.read(syncManagerProvider);
      await syncManager.manualSync();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('同步完成'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 停止旋转动画
      _refreshController.stop();
      _refreshController.reset();
    }
  }
}
