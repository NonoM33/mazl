import '../models/profile_prompt.dart';

/// Données SYNTHÉTIQUES du mode démo : prénoms inventés, e-mails en
/// `example.com`, aucune photo (les écrans affichent leurs fonds teintés).
/// Les formes JSON reprennent exactement ce que lisent les `fromJson` de
/// `lib/core/models/` et les méthodes d'`ApiService`.
abstract final class DemoFixtures {
  /// Identifiant du compte fictif côté « API » (jamais 0 : c'est le repli des
  /// décodeurs quand un identifiant manque).
  static const int meId = 1000;

  /// Profil qui répond par un match quand on le like (démo de la fenêtre).
  static const int matchOnLikeUserId = 201;

  static String isoAgo(Duration ago) =>
      DateTime.now().toUtc().subtract(ago).toIso8601String();

  static String isoIn(Duration ahead) =>
      DateTime.now().toUtc().add(ahead).toIso8601String();

  static Map<String, dynamic> _profile({
    required int userId,
    required String name,
    required int age,
    required String city,
    required String bio,
    required String denomination,
    required String kashrut,
    required String shabbat,
    required String intention,
    String gender = 'female',
    bool verified = false,
    double distance = 4,
  }) => {
    'id': userId,
    'user_id': userId,
    'display_name': name,
    'age': age,
    'gender': gender,
    'bio': bio,
    'location': city,
    'latitude': 48.8566,
    'longitude': 2.3522,
    'denomination': denomination,
    'kashrut_level': kashrut,
    'shabbat_observance': shabbat,
    'relationship_intention': intention,
    'photos': <String>[],
    'is_verified': verified,
    'verification_level': verified ? 'photo' : null,
    'distance': distance,
    'age_min': 25,
    'age_max': 38,
    'distance_max': 50,
    'looking_for': 'serious',
  };

  static Map<String, dynamic> me() => {
    ..._profile(
      userId: meId,
      name: 'Léa (démo)',
      age: 29,
      city: 'Paris',
      bio: 'Compte fictif pour parcourir l\'application sans serveur.',
      denomination: 'Massorti',
      kashrut: 'A la maison',
      shabbat: 'Partiellement',
      intention: 'serious',
      verified: true,
      distance: 0,
    ),
    'id': 1,
  };

  static Map<String, dynamic> meUser() => {
    'id': meId,
    'email': 'demo@example.com',
    'name': 'Léa (démo)',
    'picture': null,
  };

  /// Profils de la découverte (8), pratiques et intentions variées.
  static List<Map<String, dynamic>> discoverProfiles() => [
    _profile(
      userId: matchOnLikeUserId,
      name: 'Rachel',
      age: 26,
      city: 'Paris',
      bio: 'Prof de piano, dîners du vendredi soir et longues marches.',
      denomination: 'Massorti',
      kashrut: 'A la maison',
      shabbat: 'Partiellement',
      intention: 'serious',
      verified: true,
      distance: 3,
    ),
    _profile(
      userId: 202,
      name: 'Yaël',
      age: 29,
      city: 'Neuilly-sur-Seine',
      bio: 'Avocate, fan de randonnée et de challah maison.',
      denomination: 'Orthodox',
      kashrut: 'Strict',
      shabbat: 'Observant',
      intention: 'marriage',
      verified: true,
      distance: 6,
    ),
    _profile(
      userId: 203,
      name: 'David',
      age: 33,
      city: 'Lyon',
      gender: 'male',
      bio: 'Ingénieur, cuisine sépharade le dimanche.',
      denomination: 'Traditionaliste',
      kashrut: 'A la maison',
      shabbat: 'Partiellement',
      intention: 'serious',
      distance: 462,
    ),
    _profile(
      userId: 204,
      name: 'Tamar',
      age: 31,
      city: 'Paris',
      bio: 'Architecte. Je cherche quelqu\'un qui rit facilement.',
      denomination: 'Laique',
      kashrut: 'Non',
      shabbat: 'Non observant',
      intention: 'open',
      distance: 2,
    ),
    _profile(
      userId: 205,
      name: 'Samuel',
      age: 35,
      city: 'Neuilly-sur-Seine',
      gender: 'male',
      bio: 'Médecin, amateur de jazz et de voyages en Israël.',
      denomination: 'Modern Orthodox',
      kashrut: 'Strict',
      shabbat: 'Tres observant',
      intention: 'marriage',
      verified: true,
      distance: 7,
    ),
    _profile(
      userId: 206,
      name: 'Judith',
      age: 27,
      city: 'Lyon',
      bio: 'Graphiste, bénévole dans une association de quartier.',
      denomination: 'Habad',
      kashrut: 'Glatt',
      shabbat: 'Observant',
      intention: 'friends_first',
      distance: 459,
    ),
    _profile(
      userId: 207,
      name: 'Naomi',
      age: 30,
      city: 'Paris',
      bio: 'Journaliste. Le Shabbat, je déconnecte et je cuisine.',
      denomination: 'Massorti',
      kashrut: 'A la maison',
      shabbat: 'Observant',
      intention: 'serious',
      verified: true,
      distance: 5,
    ),
    _profile(
      userId: 208,
      name: 'Esther',
      age: 34,
      city: 'Paris',
      bio: 'Entrepreneuse, ouverte à tout sauf à l\'ennui.',
      denomination: 'Autre',
      kashrut: 'Non',
      shabbat: 'Non observant',
      intention: 'open',
      distance: 8,
    ),
  ];

  static List<Map<String, dynamic>> dailyPicks() =>
      discoverProfiles().take(3).toList();

  /// Profils consultables par identifiant (découverte, matchs, likes).
  static Map<String, dynamic>? profileById(int userId) {
    if (userId == meId) return me();
    for (final p in [
      ...discoverProfiles(),
      ..._matchProfiles(),
      ..._likeProfiles(),
    ]) {
      if (p['user_id'] == userId) return p;
    }
    return null;
  }

  static List<Map<String, dynamic>> _matchProfiles() => [
    _profile(
      userId: 301,
      name: 'Noémie',
      age: 28,
      city: 'Paris',
      bio: 'Sage-femme. Toujours partante pour un café.',
      denomination: 'Massorti',
      kashrut: 'A la maison',
      shabbat: 'Partiellement',
      intention: 'serious',
      verified: true,
    ),
    _profile(
      userId: 302,
      name: 'Sarah',
      age: 31,
      city: 'Neuilly-sur-Seine',
      bio: 'Dentiste, passionnée de cuisine.',
      denomination: 'Orthodox',
      kashrut: 'Strict',
      shabbat: 'Observant',
      intention: 'marriage',
      distance: 6,
    ),
    _profile(
      userId: 303,
      name: 'Myriam',
      age: 27,
      city: 'Lyon',
      bio: 'Étudiante en master, danseuse le week-end.',
      denomination: 'Traditionaliste',
      kashrut: 'A la maison',
      shabbat: 'Partiellement',
      intention: 'open',
      distance: 460,
    ),
    _profile(
      userId: 304,
      name: 'Déborah',
      age: 32,
      city: 'Paris',
      bio: 'Directrice artistique et marathonienne.',
      denomination: 'Laique',
      kashrut: 'Non',
      shabbat: 'Non observant',
      intention: 'serious',
      verified: true,
      distance: 3,
    ),
    _profile(
      userId: 305,
      name: 'Ilana',
      age: 29,
      city: 'Neuilly-sur-Seine',
      bio: 'Psychologue, amatrice de cinéma d\'auteur.',
      denomination: 'Massorti',
      kashrut: 'A la maison',
      shabbat: 'Observant',
      intention: 'friends_first',
      distance: 7,
    ),
  ];

  static List<Map<String, dynamic>> _likeProfiles() => [
    _profile(
      userId: 211,
      name: 'Elise',
      age: 28,
      city: 'Paris',
      bio: 'Photographe.',
      denomination: 'Massorti',
      kashrut: 'Non',
      shabbat: 'Non observant',
      intention: 'open',
      distance: 4,
    ),
    _profile(
      userId: 212,
      name: 'Hannah',
      age: 30,
      city: 'Paris',
      bio: 'Cheffe pâtissière.',
      denomination: 'Orthodox',
      kashrut: 'Strict',
      shabbat: 'Observant',
      intention: 'marriage',
      verified: true,
      distance: 5,
    ),
  ];

  static List<Map<String, dynamic>> matches() {
    final ages = <int, Duration>{
      301: const Duration(hours: 3),
      302: const Duration(days: 2),
      303: const Duration(days: 9),
      304: const Duration(days: 20),
      305: const Duration(days: 45),
    };
    return [
      for (final p in _matchProfiles())
        {
          'id': p['user_id'],
          'conversationId': (p['user_id'] as int) - 200,
          'matchedAt': isoAgo(ages[p['user_id']]!),
          'profile': {
            'user_id': p['user_id'],
            'display_name': p['display_name'],
            'picture': null,
            'age': p['age'],
            'location': p['location'],
            'is_verified': p['is_verified'],
          },
        },
    ];
  }

  /// (conversationId, userId, nom, dernier message, non lus, ancienneté)
  static List<Map<String, dynamic>> conversations() {
    final specs = <(int, String, int, Duration)>[
      (
        101,
        'Shabbat shalom ! Tu fais quoi vendredi soir ?',
        2,
        const Duration(minutes: 12),
      ),
      (
        102,
        'Merci pour la recommandation, je file la chercher.',
        0,
        const Duration(hours: 5),
      ),
      (
        103,
        'Haha, tu as raison. On se dit à bientôt alors ?',
        1,
        const Duration(days: 1),
      ),
      (
        104,
        'Le marathon, c\'était dur mais ça valait le coup.',
        0,
        const Duration(days: 3),
      ),
      (
        105,
        'Je t\'envoie l\'adresse du café demain.',
        0,
        const Duration(days: 8),
      ),
    ];
    final profiles = _matchProfiles();
    return [
      for (var i = 0; i < specs.length; i++)
        {
          'id': specs[i].$1,
          'matchId': 301 + i,
          'lastMessage': specs[i].$2,
          'lastMessageAt': isoAgo(specs[i].$4),
          'unreadCount': specs[i].$3,
          'otherUser': {
            'user_id': profiles[i]['user_id'],
            'display_name': profiles[i]['display_name'],
            'picture': null,
            'is_verified': profiles[i]['is_verified'],
          },
        },
    ];
  }

  /// Messages d'une conversation, du plus récent au plus ancien (ordre de
  /// l'API : l'écran de chat les affiche en liste inversée).
  static List<Map<String, dynamic>> messages(int conversationId) {
    final other = conversationId + 200;
    final last =
        conversations().firstWhere(
              (c) => c['id'] == conversationId,
            )['lastMessage']
            as String;
    final unread =
        conversations().firstWhere(
              (c) => c['id'] == conversationId,
            )['unreadCount']
            as int;
    final script = <(int, String, Duration)>[
      (other, last, const Duration(minutes: 12)),
      (
        meId,
        'Plutôt dîner chez des amis, et toi ?',
        const Duration(minutes: 40),
      ),
      (other, 'Salut ! Ravie qu\'on ait matché.', const Duration(hours: 2)),
      (
        meId,
        'Salut ! Comment s\'est passée ta semaine ?',
        const Duration(hours: 3),
      ),
    ];
    return [
      for (var i = 0; i < script.length; i++)
        {
          'id': conversationId * 100 + (script.length - i),
          'sender_id': script[i].$1,
          'content': script[i].$2,
          'image_url': null,
          'message_type': 'text',
          'is_read': !(i == 0 && script[i].$1 == other && unread > 0),
          'created_at': isoAgo(script[i].$3),
        },
    ];
  }

  static Map<String, dynamic> likesReceived() {
    final likes = [
      for (final (i, p) in [
        ..._likeProfiles(),
        profileById(matchOnLikeUserId)!,
      ].indexed)
        {
          'user_id': p['user_id'],
          'display_name': p['display_name'],
          'picture': null,
          'age': p['age'],
          'is_verified': p['is_verified'],
          'liked_at': isoAgo(Duration(hours: 2 + i * 7)),
          'distance': p['distance'],
        },
    ];
    return {
      'success': true,
      'count': likes.length,
      'is_premium': true,
      'likes': likes,
    };
  }

  static List<Map<String, dynamic>> events() => [
    {
      'id': 1,
      'title': 'Dîner de Shabbat communautaire',
      'description': 'Un dîner convivial pour se rencontrer, ouvert à tous.',
      'event_type': 'social',
      'location': 'Centre communautaire',
      'address': '12 rue de l\'Exemple, Paris',
      'latitude': 48.857,
      'longitude': 2.35,
      'date': isoIn(const Duration(days: 4)),
      'time': '19:30',
      'end_time': '22:30',
      'price': 25,
      'currency': 'EUR',
      'max_attendees': 40,
      'attendee_count': 31,
      'image_url': null,
      'is_published': true,
      'user_rsvp_status': null,
    },
    {
      'id': 2,
      'title': 'Brunch du dimanche',
      'description': 'Brunch décontracté pour les 25-35 ans.',
      'event_type': 'brunch',
      'location': 'Café Exemple',
      'address': '3 avenue de la Démo, Neuilly-sur-Seine',
      'latitude': 48.884,
      'longitude': 2.269,
      'date': isoIn(const Duration(days: 9)),
      'time': '11:00',
      'end_time': '14:00',
      'price': 0,
      'currency': 'EUR',
      'max_attendees': null,
      'attendee_count': 12,
      'image_url': null,
      'is_published': true,
      'user_rsvp_status': null,
    },
    {
      'id': 3,
      'title': 'Soirée Pourim à Lyon',
      'description': 'Costumes, musique et mishloach manot.',
      'event_type': 'party',
      'location': 'Salle des fêtes',
      'address': '8 place de la Fiction, Lyon',
      'latitude': 45.764,
      'longitude': 4.835,
      'date': isoIn(const Duration(days: 20)),
      'time': '20:00',
      'end_time': '01:00',
      'price': 15,
      'currency': 'EUR',
      'max_attendees': 80,
      'attendee_count': 80,
      'image_url': null,
      'is_published': true,
      'user_rsvp_status': 'going',
    },
  ];

  static List<Map<String, dynamic>> myPrompts() => [
    {
      'id': 1,
      'prompt_id': 'shabbat_ideal',
      'prompt_text': 'Mon Shabbat idéal...',
      'answer': 'Une grande tablée, du vin, et personne sur son téléphone.',
      'position': 1,
    },
    {
      'id': 2,
      'prompt_id': 'fun_fact',
      'prompt_text': 'Un fait surprenant sur moi...',
      'answer': 'J\'ai appris le yiddish avec ma grand-mère.',
      'position': 2,
    },
  ];

  static List<Map<String, dynamic>> promptTemplates() =>
      PromptTemplate.defaultPrompts.map(Map<String, dynamic>.of).toList();
}
