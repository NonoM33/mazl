import '../../../core/router/route_names.dart';
import '../../../core/services/api_service.dart';

/// La conversation ouverte avec [userId], ou `null` si elle n'existe pas
/// encore (le serveur la crée au match mais ne renvoie pas son id).
int? conversationIdWith(List<Conversation> conversations, int userId) {
  for (final conversation in conversations) {
    if (conversation.otherUser?.userId == userId) return conversation.id;
  }
  return null;
}

/// Où mène « Envoyer un message » après un match : la conversation avec
/// [userId], ou Messages tant qu'elle n'est pas trouvée.
Future<String> conversationRouteWith(ApiService api, int userId) async {
  final response = await api.getConversations();
  final id = response.success ? conversationIdWith(response.data ?? const [], userId) : null;
  return id == null ? RoutePaths.chat : '/chat/$id';
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

/// Vrai quand la liste Messages redevient visible : retour sur l'onglet ou
/// sortie d'une conversation. L'écran reste vivant dans son onglet, il doit
/// donc se recharger lui-même (un nouveau match n'y apparaissait pas).
bool conversationListBecameVisible(String? previousPath, String currentPath) =>
    currentPath == RoutePaths.chat && previousPath != RoutePaths.chat;
