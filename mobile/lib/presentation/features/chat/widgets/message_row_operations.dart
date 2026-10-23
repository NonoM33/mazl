import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/widgets/mazl_sheet.dart';
import '../state/chat_controller_impl.dart';
import '../logic/chat_items.dart';
import '../state/chat_controller.dart';
import 'chat_feedback.dart';
import 'chat_scope.dart';
import 'message_actions_overlay.dart';
import 'report_sheet.dart';

/// What a row does on a gesture: menu entries and their effects. The row owns
/// the layout, this owns the behaviour.
class RowOperations {
  RowOperations(this.context, this.ref, this.scope, this.item);

  final BuildContext context;
  final WidgetRef ref;
  final ChatScope scope;
  final MessageItem item;

  ChatMessage get message => item.message;
  ChatActions get _actions => ref.read(chatControllerProvider(scope.conversationId).notifier);

  bool get canMenu => !message.unsent && (!message.isLocal || message.status == MessageStatus.failed);
  bool get failed => message.status == MessageStatus.failed;

  Set<String> get myReactions => {
        for (final r in message.reactions)
          if (r.userIds.contains(scope.myUserId)) r.emoji,
      };

  Future<void> react(String emoji) async {
    final error = await _actions.toggleReaction(message.id, emoji);
    if (context.mounted) showChatError(context, error);
  }

  /// Double tap: the heart. True when it was ADDED (so the caller pops it).
  bool heart() {
    if (message.isLocal || message.unsent) return false;
    HapticFeedback.lightImpact();
    final added = !myReactions.contains('❤️');
    react('❤️');
    return added;
  }

  bool get canUnsend =>
      item.mine && !message.isLocal && DateTime.now().difference(message.createdAt) < unsendWindow;

  List<MessageMenuAction> menu() {
    if (failed) {
      return [
        MessageMenuAction(label: 'Réessayer', icon: LucideIcons.rotateCw, onTap: retry),
        MessageMenuAction(label: 'Supprimer', icon: LucideIcons.trash2, destructive: true, onTap: discard),
      ];
    }
    return [
      MessageMenuAction(label: 'Répondre', icon: MenuIcons.reply, onTap: () => scope.onReply(message)),
      if (message.content.isNotEmpty) MessageMenuAction(label: 'Copier', icon: MenuIcons.copy, onTap: copy),
      if (canUnsend) MessageMenuAction(label: 'Retirer', icon: MenuIcons.unsend, destructive: true, onTap: unsend),
      if (!item.mine) MessageMenuAction(label: 'Signaler', icon: MenuIcons.report, destructive: true, onTap: report),
    ];
  }

  void copy() {
    Clipboard.setData(ClipboardData(text: message.content));
    showChatSnack(context, 'Message copié');
  }

  Future<void> unsend() async {
    final error = await _actions.unsend(message.id);
    if (context.mounted) showChatError(context, error);
  }

  Future<void> report() async {
    final reason = await pickReportReason(context);
    if (reason == null || !context.mounted) return;
    final error = await _actions.report(message.id, reason);
    if (!context.mounted) return;
    showChatSnack(context, error ?? 'Merci, nous examinons ce message.');
  }

  Future<void> retry() async {
    final id = message.clientId;
    if (id == null) return;
    final error = await _actions.retry(id);
    if (context.mounted) showChatError(context, error);
  }

  void discard() {
    final id = message.clientId;
    if (id != null) _actions.discard(id);
  }

  /// Tap on « Échec · Réessayer ».
  Future<void> failedMenu() {
    return showMazlSheet<void>(
      context,
      padded: false,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.rotateCw),
            title: const Text('Réessayer'),
            onTap: () {
              Navigator.pop(sheet);
              retry();
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.trash2, color: Theme.of(sheet).colorScheme.error),
            title: Text('Supprimer', style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
            onTap: () {
              Navigator.pop(sheet);
              discard();
            },
          ),
        ],
      ),
    );
  }
}
