import '../../../../l10n/l10n.dart';
import '../state/chat_controller.dart';

/// The sentence for a failed chat action, in the member's language.
extension ChatFailureText on ChatFailure {
  String text(AppLocalizations l10n) => switch (this) {
    ChatFailure.sessionExpired => l10n.chatErrorSessionExpired,
    ChatFailure.cannotUnsend => l10n.chatErrorCannotUnsend,
    ChatFailure.conversationGone => l10n.chatErrorConversationGone,
    ChatFailure.blocked => l10n.chatErrorBlocked,
    ChatFailure.tooLarge => l10n.chatErrorTooLarge,
    ChatFailure.rateLimited => l10n.chatErrorRateLimited,
    ChatFailure.server => l10n.chatErrorServer,
    ChatFailure.fileRejected => l10n.chatErrorFileRejected,
    ChatFailure.messageRejected => l10n.chatErrorMessageRejected,
    ChatFailure.timeout => l10n.chatErrorTimeout,
    ChatFailure.network => l10n.chatErrorNetwork,
    ChatFailure.unknown => l10n.chatErrorUnknown,
    ChatFailure.tooManyPhotos => l10n.chatErrorTooManyPhotos,
    ChatFailure.notYetSent => l10n.chatErrorNotYetSent,
    ChatFailure.messageGone => l10n.chatErrorMessageGone,
    ChatFailure.notAuthor => l10n.chatErrorNotAuthor,
    ChatFailure.reactionUnavailable => l10n.chatErrorReactionUnavailable,
    ChatFailure.sendUnavailable => l10n.chatErrorSendUnavailable,
    ChatFailure.loadFailed => l10n.chatErrorLoadFailed,
  };
}
