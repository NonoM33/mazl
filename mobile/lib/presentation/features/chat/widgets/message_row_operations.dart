import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
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
  ChatActions get _actions =>
      ref.read(chatControllerProvider(scope.conversationId).notifier);

  bool get canMenu =>
      !message.unsent &&
      (!message.isLocal || message.status == MessageStatus.failed);
  bool get failed => message.status == MessageStatus.failed;

  Set<String> get myReactions => {
    for (final r in message.reactions)
      if (r.userIds.contains(scope.myUserId)) r.emoji,
  };

  Future<void> react(String emoji) async {
    final failure = await _actions.toggleReaction(message.id, emoji);
    if (context.mounted) showChatError(context, failure);
  }

  /// Double tap: the heart. True when it was ADDED (so the caller pops it).
  bool heart() {
    if (message.isLocal || message.unsent) return false;
    HapticFeedback.lightImpact();
    final heart = allowedReactions.first;
    final added = !myReactions.contains(heart);
    react(heart);
    return added;
  }

  bool get canUnsend =>
      item.mine &&
      !message.isLocal &&
      DateTime.now().difference(message.createdAt) < unsendWindow;

  List<MessageMenuAction> menu() {
    final l10n = context.l10n;
    if (failed) {
      return [
        MessageMenuAction(
          label: l10n.commonRetry,
          icon: LucideIcons.rotateCw,
          onTap: retry,
        ),
        MessageMenuAction(
          label: l10n.commonDelete,
          icon: LucideIcons.trash2,
          destructive: true,
          onTap: discard,
        ),
      ];
    }
    return [
      MessageMenuAction(
        label: l10n.chatMenuReply,
        icon: MenuIcons.reply,
        mirrorsInRtl: true,
        onTap: () => scope.onReply(message),
      ),
      if (message.content.isNotEmpty)
        MessageMenuAction(
          label: l10n.chatMenuCopy,
          icon: MenuIcons.copy,
          onTap: copy,
        ),
      if (canUnsend)
        MessageMenuAction(
          label: l10n.chatMenuUnsend,
          icon: MenuIcons.unsend,
          mirrorsInRtl: true,
          destructive: true,
          onTap: unsend,
        ),
      if (!item.mine)
        MessageMenuAction(
          label: l10n.commonReport,
          icon: MenuIcons.report,
          destructive: true,
          onTap: report,
        ),
    ];
  }

  void copy() {
    Clipboard.setData(ClipboardData(text: message.content));
    showChatSnack(context, context.l10n.chatCopied);
  }

  Future<void> unsend() async {
    final failure = await _actions.unsend(message.id);
    if (context.mounted) showChatError(context, failure);
  }

  Future<void> report() async {
    final reason = await pickReportReason(context);
    if (reason == null || !context.mounted) return;
    final failure = await _actions.report(message.id, reason.wire);
    if (!context.mounted) return;
    if (failure != null) return showChatError(context, failure);
    showChatSnack(context, context.l10n.chatReportThanks);
  }

  Future<void> retry() async {
    final id = message.clientId;
    if (id == null) return;
    final failure = await _actions.retry(id);
    if (context.mounted) showChatError(context, failure);
  }

  void discard() {
    final id = message.clientId;
    if (id != null) _actions.discard(id);
  }

  /// Tap on the failure line (« Échec · Réessayer » in French).
  Future<void> failedMenu() {
    return showMazlSheet<void>(
      context,
      padded: false,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.rotateCw),
            title: Text(sheet.l10n.commonRetry),
            onTap: () {
              Navigator.pop(sheet);
              retry();
            },
          ),
          ListTile(
            leading: Icon(
              LucideIcons.trash2,
              color: Theme.of(sheet).colorScheme.error,
            ),
            title: Text(
              sheet.l10n.commonDelete,
              style: TextStyle(color: Theme.of(sheet).colorScheme.error),
            ),
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
