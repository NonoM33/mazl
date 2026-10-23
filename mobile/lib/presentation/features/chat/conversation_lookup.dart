import '../../../core/models/conversation.dart';

/// La conversation ouverte avec [userId], ou `null` si elle n'existe pas
/// encore (le serveur la crée au match mais ne renvoie pas son id).
int? conversationIdWith(List<Conversation> conversations, int userId) {
  for (final conversation in conversations) {
    if (conversation.otherUser?.userId == userId) return conversation.id;
  }
  return null;
}

/// Copie de [conversations] où [conversationId] n'a plus de non-lu : la
/// liste reflète tout de suite l'ouverture, sans attendre le serveur.
List<Conversation> markConversationRead(List<Conversation> conversations, int conversationId) => [
      for (final c in conversations)
        if (c.id == conversationId)
          Conversation(
            id: c.id,
            matchId: c.matchId,
            lastMessage: c.lastMessage,
            lastMessageAt: c.lastMessageAt,
            otherUser: c.otherUser,
          )
        else
          c,
    ];
