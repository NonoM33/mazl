import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/theme/app_colors.dart';
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
    if (user != null) context.push(RoutePaths.matchProfilePath(user.userId.toString()));
  }

  void _openBlockReportDialog() {
    final user = _otherUser;
    if (user == null) return;
    BlockReportDialog.show(
      context,
      userId: user.userId,
      userName: user.displayName ?? 'Cet utilisateur',
      onBlocked: () {
        if (mounted) context.pop();
      },
    );
  }

  Future<void> _muteConversation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('muted_conversation_$_conversationId', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications coupées pour cette conversation')));
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
            title: const Text('Voir le profil'),
            onTap: () {
              Navigator.pop(sheet);
              _openProfile();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.bellOff),
            title: const Text('Couper les notifications'),
            onTap: () {
              Navigator.pop(sheet);
              _muteConversation();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.flag),
            title: const Text('Signaler'),
            onTap: () {
              Navigator.pop(sheet);
              _openBlockReportDialog();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.userX, color: AppColors.error),
            title: const Text('Bloquer', style: TextStyle(color: AppColors.error)),
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
