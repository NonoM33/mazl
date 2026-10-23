import 'demo_chat_state.dart';
import 'demo_fixtures.dart';

/// Les conversations de départ de la démo, converties à la forme du contrat
/// (docs/chat/CONTRAT.md §1) et recalées sur l'horloge de la démo.
abstract final class DemoChatSeed {
  /// Messages d'une conversation de départ, du plus ancien au plus récent.
  /// Une conversation ouverte par un match n'en a aucun.
  static List<DemoChatMessage> messages(
    int conversationId,
    DateTime now,
    int myId,
    int Function() nextId,
  ) {
    final header = DemoFixtures.conversations()
        .where((c) => c['id'] == conversationId)
        .firstOrNull;
    if (header == null) return [];
    var unread = header['unreadCount'] as int;
    final realNow = DateTime.now().toUtc();
    final newestFirst = DemoFixtures.messages(conversationId);
    final result = <DemoChatMessage>[];
    for (final raw in newestFirst) {
      final age = realNow.difference(
        DateTime.parse(raw['created_at'] as String),
      );
      final createdAt = now.subtract(age);
      final mine = raw['sender_id'] == myId;
      final isUnread = !mine && unread > 0;
      if (isUnread) unread--;
      result.add(
        DemoChatMessage(
          id: raw['id'] as int,
          conversationId: conversationId,
          senderId: raw['sender_id'] as int,
          type: 'text',
          content: raw['content'] as String,
          createdAt: createdAt,
          readAt: isUnread ? null : createdAt.add(const Duration(minutes: 1)),
        ),
      );
    }
    return result.reversed.toList();
  }

  /// Aperçu fictif d'un lien : le serveur réel ne va pas chercher la page.
  static Map<String, dynamic> linkPreview(String url) {
    final host = Uri.tryParse(url)?.host ?? url;
    return {
      'url': url,
      'title': host,
      'description': 'Aperçu de démonstration',
      'image_url': null,
      'site_name': host,
    };
  }
}
