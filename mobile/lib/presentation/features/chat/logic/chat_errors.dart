/// Shown, and the composer disabled, when the server refuses writes in this
/// conversation (403: the pair is blocked).
const blockedConversationMessage =
    'Vous ne pouvez plus écrire dans cette conversation.';

/// What the controller says when the conversation is gone for good (404, or
/// 403 on a read): the thread is read-only too.
const unavailableConversationMessage =
    'Cette conversation n’est plus disponible.';

/// True when [error], returned by a send action, means nobody can write here
/// any more.
bool isBlockedError(String? error) =>
    error == blockedConversationMessage ||
    error == unavailableConversationMessage;
