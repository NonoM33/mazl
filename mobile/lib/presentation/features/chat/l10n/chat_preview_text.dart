import '../../../../core/chat/chat_realtime.dart';
import '../../../../l10n/l10n.dart';

/// One line of a message as the server wrote it (`lastMessage`,
/// `reply_to.preview`): « Photo », « Message vocal » and « Message retiré »
/// are the server's words for what is not text, shown here in the member's
/// language; a text is shown as it is.
String chatPreviewLabel(AppLocalizations l10n, String wire) =>
    switch (chatPreviewKindOf(wire)) {
      ChatPreviewKind.photo => l10n.chatPhotoLabel,
      ChatPreviewKind.voice => l10n.chatVoiceLabel,
      ChatPreviewKind.removed => l10n.chatRemovedLabel,
      ChatPreviewKind.text => wire,
    };
