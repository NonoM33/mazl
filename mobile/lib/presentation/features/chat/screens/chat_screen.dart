import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/block_report_dialog.dart';
import '../../../common/widgets/mazl_sheet.dart';
import 'chat_conversation_screen.dart';

/// Route entry of a conversation: finds who it is with, then hands over to
/// [ChatConversationScreen], which owns the thread, the gestures and the composer.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ConversationUser? _otherUser;

  int get _conversationId => int.tryParse(widget.conversationId) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
  }

  Future<void> _loadOtherUser() async {
    final response = await ApiService().getConversations();
    final conversations = response.data;
    if (!response.success || conversations == null || !mounted) return;
    for (final conversation in conversations) {
      if (conversation.id == _conversationId) {
        setState(() => _otherUser = conversation.otherUser);
        return;
      }
    }
  }

  void _openProfile() {
    final user = _otherUser;
    if (user != null) {
      context.push(RoutePaths.matchProfilePath(user.userId.toString()));
    }
  }

  void _openBlockReportDialog() {
    final user = _otherUser;
    if (user == null) return;
    BlockReportDialog.show(
      context,
      userId: user.userId,
      userName: user.displayName ?? context.l10n.chatBlockFallbackName,
      onBlocked: () {
        if (mounted) context.pop();
      },
    );
  }

  Future<void> _muteConversation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('muted_conversation_$_conversationId', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.chatMutedConfirmation)),
    );
  }

  void _showOptions() {
    showMazlSheet<void>(
      context,
      padded: false,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.user),
            title: Text(sheet.l10n.chatOptionsViewProfile),
            onTap: () {
              Navigator.pop(sheet);
              _openProfile();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.bellOff),
            title: Text(sheet.l10n.chatOptionsMute),
            onTap: () {
              Navigator.pop(sheet);
              _muteConversation();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.flag),
            title: Text(sheet.l10n.commonReport),
            onTap: () {
              Navigator.pop(sheet);
              _openBlockReportDialog();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.userX, color: AppColors.error),
            title: Text(
              sheet.l10n.chatOptionsBlock,
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(sheet);
              _openBlockReportDialog();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ChatConversationScreen(
    conversationId: _conversationId,
    otherUser: _otherUser,
    onBack: () => context.pop(),
    onOpenProfile: _openProfile,
    onVideoCall: () => context.go('/chat/${widget.conversationId}/video-call'),
    onOptions: _showOptions,
  );
}
