import 'demo_fixtures.dart';

/// État mutable du mode démo, en mémoire seulement : un message envoyé reste
/// visible quand on rouvre la conversation, une lecture vide le compteur…
/// Il est remis à zéro à chaque démarrage de session fictive.
abstract final class DemoStore {
  static final Map<int, List<Map<String, dynamic>>> _sent = {};
  static final Set<int> _read = {};
  static final Map<int, String?> _rsvp = {};
  static Map<String, dynamic> _profilePatch = {};
  static List<Map<String, dynamic>> _prompts = DemoFixtures.myPrompts();
  static bool _boostActive = false;
  static bool _photoVerified = false;
  static bool _identityVerified = false;
  static int _nextId = 9000;

  /// Conversations ouvertes par un match pendant la session, comme le fait
  /// le serveur (`createConversationForMatch`).
  static final List<Map<String, dynamic>> _matched = [];

  static void reset() {
    _sent.clear();
    _read.clear();
    _rsvp.clear();
    _profilePatch = {};
    _prompts = DemoFixtures.myPrompts();
    _boostActive = false;
    _photoVerified = false;
    _identityVerified = false;
    _nextId = 9000;
    _matched.clear();
  }

  /// Crée (une seule fois) la conversation d'un nouveau match.
  static void openMatchConversation(Map<String, dynamic> profile) {
    final userId = profile['user_id'];
    if (_matched.any((c) => c['otherUser']['user_id'] == userId)) return;
    final id = nextId();
    _matched.add({
      'id': id,
      'matchId': id,
      'lastMessage': null,
      'lastMessageAt': DemoFixtures.isoAgo(Duration.zero),
      'unreadCount': 0,
      'otherUser': {
        'user_id': userId,
        'display_name': profile['display_name'],
        'picture': null,
        'is_verified': profile['is_verified'],
      },
    });
  }

  static int nextId() => _nextId++;

  // Vérification (docs/verification/CONTRAT.md §3-4), simulée pour la session.
  static bool get photoVerified => _photoVerified;
  static bool get identityVerified => _identityVerified;
  static void setPhotoVerified(bool verified) => _photoVerified = verified;
  static void markIdentityVerified() => _identityVerified = true;

  static Map<String, dynamic> myProfile() => {
    ...DemoFixtures.me(),
    ..._profilePatch,
  };

  static void patchProfile(Map<String, dynamic> body) {
    // L'app envoie des clés camelCase (kashrutLevel…), l'API en renvoie en
    // snake_case : on traduit celles qu'elle édite.
    const renames = {
      'displayName': 'display_name',
      'kashrutLevel': 'kashrut_level',
      'shabbatObservance': 'shabbat_observance',
      'relationshipIntention': 'relationship_intention',
      'lookingFor': 'looking_for',
    };
    body.forEach((key, value) {
      if (value != null) _profilePatch[renames[key] ?? key] = value;
    });
  }

  static List<Map<String, dynamic>> conversations() => [
    for (final c in _matched)
      {
        ...c,
        if (_sent[c['id']]?.isNotEmpty ?? false) ...{
          'lastMessage': _sent[c['id']]!.first['content'],
          'lastMessageAt': _sent[c['id']]!.first['created_at'],
        },
      },
    for (final c in DemoFixtures.conversations())
      {
        ...c,
        if (_read.contains(c['id'])) 'unreadCount': 0,
        if (_sent[c['id']]?.isNotEmpty ?? false) ...{
          'lastMessage': _sent[c['id']]!.first['content'],
          'lastMessageAt': _sent[c['id']]!.first['created_at'],
        },
      },
  ];

  static List<Map<String, dynamic>> messages(int conversationId) => [
    ...?_sent[conversationId],
    if (!_matched.any((c) => c['id'] == conversationId))
      ...DemoFixtures.messages(conversationId),
  ];

  static Map<String, dynamic> sendMessage(int conversationId, String content) {
    final message = {
      'id': nextId(),
      'sender_id': DemoFixtures.meId,
      'content': content,
      'image_url': null,
      'message_type': 'text',
      'is_read': false,
      'created_at': DemoFixtures.isoAgo(Duration.zero),
    };
    _sent.putIfAbsent(conversationId, () => []).insert(0, message);
    return message;
  }

  static void markRead(int conversationId) => _read.add(conversationId);

  static List<Map<String, dynamic>> events() => [
    for (final e in DemoFixtures.events())
      {
        ...e,
        if (_rsvp.containsKey(e['id'])) 'user_rsvp_status': _rsvp[e['id']],
      },
  ];

  static void setRsvp(int eventId, String? status) => _rsvp[eventId] = status;

  static List<Map<String, dynamic>> prompts() => List.of(_prompts);

  static Map<String, dynamic> addPrompt(Map<String, dynamic> body) {
    final promptId = body['prompt_id'] as String? ?? 'fun_fact';
    final template = DemoFixtures.promptTemplates().firstWhere(
      (t) => t['id'] == promptId,
      orElse: () => {'text': ''},
    );
    final prompt = {
      'id': nextId(),
      'prompt_id': promptId,
      'prompt_text': template['text'],
      'answer': body['answer'] ?? '',
      'position': body['position'] ?? _prompts.length + 1,
    };
    _prompts.add(prompt);
    return prompt;
  }

  static Map<String, dynamic>? updatePrompt(int id, String answer) {
    final index = _prompts.indexWhere((p) => p['id'] == id);
    if (index < 0) return null;
    return _prompts[index] = {..._prompts[index], 'answer': answer};
  }

  static void deletePrompt(int id) =>
      _prompts.removeWhere((p) => p['id'] == id);

  static bool get boostActive => _boostActive;
  static void activateBoost() => _boostActive = true;
}
