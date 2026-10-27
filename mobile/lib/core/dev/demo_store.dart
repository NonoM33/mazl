import 'demo_chat_state.dart';
import 'demo_couple_state.dart';
import 'demo_fixtures.dart';
import 'demo_money_routes.dart';
import 'demo_premium_routes.dart';
import 'demo_photos.dart';

/// État mutable du mode démo, en mémoire seulement : un message envoyé reste
/// visible quand on rouvre la conversation, une lecture vide le compteur…
/// Il est remis à zéro à chaque démarrage de session fictive.
/// A consent decision of the demo member.
typedef DemoConsent = ({bool granted, String version, DateTime decidedAt});

abstract final class DemoStore {
  static final Map<String, DemoConsent> _consents = {};

  /// The demo member's decision for a consent purpose, if any.
  static DemoConsent? consent(String purpose) => _consents[purpose];

  static DemoConsent decideConsent(
    String purpose,
    bool granted,
    String version,
  ) => _consents[purpose] = (
    granted: granted,
    version: version,
    decidedAt: clock(),
  );

  static final Map<int, String?> _rsvp = {};
  static final Set<int> _eventAlerts = {};
  static Map<String, dynamic> _profilePatch = {};
  static List<Map<String, dynamic>> _prompts = DemoFixtures.myPrompts();
  static bool _boostActive = false;
  static int _superLikesLeft = _freeSuperLikesPerDay;
  static int _boostsLeft = _boostsBought;
  static bool _photoVerified = false;
  static bool _identityVerified = false;
  static Map<String, dynamic> _discoverFilters = _noDiscoverFilters();
  static int _nextId = 9000;

  static Map<String, dynamic> _noDiscoverFilters() => {
    'denominations': null,
    'kashrutLevels': null,
    'shabbatObservances': null,
    'onlyVerified': false,
    'onlyWithPhoto': false,
  };

  /// Filtres avancés de Découvrir (le membre fictif est mazl+).
  static Map<String, dynamic> get discoverFilters => Map.of(_discoverFilters);

  /// Applique un PUT partiel : une clé absente ne change rien, `null` efface.
  static Map<String, dynamic> patchDiscoverFilters(Map<String, dynamic> patch) {
    for (final key in _discoverFilters.keys.toList()) {
      if (patch.containsKey(key)) {
        _discoverFilters[key] = patch[key] ?? _noDiscoverFilters()[key];
      }
    }
    return discoverFilters;
  }

  /// Horloge de la démo : les tests l'avancent au lieu d'attendre.
  static DateTime Function() clock = DateTime.now;

  /// Messagerie de la session (messages, médias, correspondant fictif).
  static DemoChatState chat = _newChat();

  static DemoChatState _newChat() => DemoChatState()
    ..myId = DemoFixtures.meId
    ..otherUserOf = _otherUserOf;

  static int _otherUserOf(int conversationId) =>
      conversationHeader(conversationId)?['otherUser']['user_id'] as int;

  /// Mode couple de la session (demandes, couple, contenus).
  static DemoCoupleState couple = DemoCoupleState();

  /// Conversations ouvertes par un match pendant la session, comme le fait
  /// le serveur (`createConversationForMatch`).
  static final List<Map<String, dynamic>> _matched = [];

  static void reset() {
    chat = _newChat();
    _rsvp.clear();
    _eventAlerts.clear();
    _profilePatch = {};
    _prompts = DemoFixtures.myPrompts();
    _boostActive = false;
    _superLikesLeft = _freeSuperLikesPerDay;
    _boostsLeft = _boostsBought;
    _photoVerified = false;
    _identityVerified = false;
    _discoverFilters = _noDiscoverFilters();
    _nextId = 9000;
    _matched.clear();
    _consents.clear();
    couple = DemoCoupleState();
    DemoMoneyRoutes.reset();
    DemoPremiumRoutes.reset();
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
        'picture': DemoPhotos.avatar(userId as int),
        'is_verified': profile['is_verified'],
      },
    });
  }

  /// Vrai si [userId] est un match (liste de départ ou match ouvert pendant
  /// la session).
  static bool isMatch(int userId) =>
      DemoFixtures.matches().any((m) => m['id'] == userId) ||
      _matched.any((c) => c['otherUser']['user_id'] == userId);

  static int nextId() => _nextId++;

  // Vérification (docs/verification/CONTRAT.md §3-4), simulée pour la session.
  static bool get photoVerified => _photoVerified;
  static bool get identityVerified => _identityVerified;
  static void setPhotoVerified(bool verified) => _photoVerified = verified;
  static void markIdentityVerified() => _identityVerified = true;

  static Map<String, dynamic> myProfile() => {
    ...DemoFixtures.me(),
    ..._profilePatch,
    // Comme le serveur : le badge découle du statut de vérification, jamais
    // d'un drapeau figé dans les données fictives.
    ..._verificationBadge(),
  };

  static Map<String, dynamic> _verificationBadge() => {
    'is_verified': _photoVerified || _identityVerified,
    'photo_verified': _photoVerified,
    'identity_verified': _identityVerified,
    'verification_level': _identityVerified
        ? 'identity'
        : (_photoVerified ? 'photo' : 'none'),
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

  /// La conversation telle que les données de départ la décrivent (sans les
  /// messages de la session).
  static Map<String, dynamic>? conversationHeader(int id) => [
    ..._matched,
    ...DemoFixtures.conversations(),
  ].where((c) => c['id'] == id).firstOrNull;

  static bool hasConversation(int id) => conversationHeader(id) != null;

  static Iterable<int> conversationIds() => [
    for (final c in [..._matched, ...DemoFixtures.conversations()])
      c['id'] as int,
  ];

  static List<Map<String, dynamic>> conversations() {
    final now = clock();
    chat.settle(now);
    return [
      for (final c in [..._matched, ...DemoFixtures.conversations()])
        _withMessages(c, now),
    ];
  }

  /// Dernier message et non-lus tels que la messagerie les voit.
  static Map<String, dynamic> _withMessages(
    Map<String, dynamic> c,
    DateTime now,
  ) {
    final id = c['id'] as int;
    final last = chat.latest(id, now);
    return {
      ...c,
      'unreadCount': chat.unreadCount(id, now),
      if (last != null) ...{
        'lastMessage': last.summary,
        'lastMessageAt': last.createdAt.toUtc().toIso8601String(),
      },
    };
  }

  static List<Map<String, dynamic>> events() => [
    for (final e in DemoFixtures.events())
      {
        ...e,
        if (_rsvp.containsKey(e['id'])) 'user_rsvp_status': _rsvp[e['id']],
        if (e['availability'] == 'coming_soon')
          'notify_requested': _eventAlerts.contains(e['id']),
      },
  ];

  static void setRsvp(int eventId, String? status) => _rsvp[eventId] = status;

  /// « Me prévenir » on a coming soon event.
  static void setEventAlert(int eventId, {required bool requested}) =>
      requested ? _eventAlerts.add(eventId) : _eventAlerts.remove(eventId);

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

  /// Allumé : le boost tourne, et un second n'est pas débité (HTTP 409).
  static void activateBoost() => _boostActive = true;

  // --- Crédits : un membre gratuit (1 Super Like par jour) qui a déjà acheté
  // un Boost. La démo n'a pas de store : une fois épuisés, le serveur fictif
  // répond 402 comme le vrai.
  static const int _freeSuperLikesPerDay = 1;
  static const int _boostsBought = 1;

  static int get superLikesLeft => _superLikesLeft;
  static int get boostsLeft => _boostsLeft;

  /// Dépense un Super Like ; faux s'il n'en reste pas.
  static bool spendSuperLike() {
    if (_superLikesLeft <= 0) return false;
    _superLikesLeft--;
    return true;
  }

  /// Dépense un Boost ; faux s'il n'en reste pas.
  static bool spendBoost() {
    if (_boostsLeft <= 0) return false;
    _boostsLeft--;
    return true;
  }
}
