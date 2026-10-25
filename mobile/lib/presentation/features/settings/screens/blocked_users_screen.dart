import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// Screen to manage blocked users
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ApiService _apiService = ApiService();
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getBlockedUsers();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _blockedUsers = result.data ?? [];
        } else {
          _error = result.error;
        }
      });
    }
  }

  Future<void> _unblockUser(BlockedUser user) async {
    final name = user.displayName;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.settingsBlockedUnblockTitle),
        content: Text(
          name == null
              ? context.l10n.settingsBlockedUnblockMessageUnnamed
              : context.l10n.settingsBlockedUnblockMessage(name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.settingsBlockedUnblock),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.unblockUser(user.userId);

    if (mounted) {
      final l10n = context.l10n;
      if (result.success) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.userId == user.userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              name == null
                  ? l10n.settingsBlockedUnblockedUnnamed
                  : l10n.settingsBlockedUnblocked(name),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsBlockedUnblockError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsBlockedUsers),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.l10n.commonLoadError,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadBlockedUsers,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.userCheck, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              context.l10n.settingsBlockedEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.settingsBlockedEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final user = _blockedUsers[index];
          return _BlockedUserTile(
            user: user,
            onUnblock: () => _unblockUser(user),
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.onUnblock,
  });

  final BlockedUser user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundImage: user.picture != null
            ? CachedNetworkImageProvider(user.picture!)
            : null,
        child: user.picture == null
            ? Text(
                (user.displayName?.isNotEmpty == true)
                    ? user.displayName![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayName ?? context.l10n.settingsBlockedUserFallbackName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        context.l10n.settingsBlockedOn(user.blockedAt),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: TextButton(
        onPressed: onUnblock,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
        child: Text(context.l10n.settingsBlockedUnblock),
      ),
    );
  }
}
