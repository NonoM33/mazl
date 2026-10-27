import '../models/profile_prompt.dart';
import 'demo_photos.dart';

/// Données SYNTHÉTIQUES du mode démo : prénoms inventés, e-mails en
/// `example.com`, photos Unsplash chargées depuis le réseau (voir `DemoPhotos`), sauf pour
/// le compte démo, volontairement sans photo.
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
    'photos': DemoPhotos.of(userId),
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
    {
      // Un Super Like reçu, avec son mot (GET /api/discover).
      ..._profile(
        userId: matchOnLikeUserId,
        name: 'Rachel',
        age: 26,
        city: 'Paris',
        bio:
            'Prof de piano, je donne des cours à Paris et je joue dans une chorale. Dîners du vendredi soir, longues marches au bord du canal : je cherche quelqu\'un de curieux et de tendre.',
        denomination: 'Massorti',
        kashrut: 'A la maison',
        shabbat: 'Partiellement',
        intention: 'serious',
        verified: true,
        distance: 3,
      ),
      'super_liked_you': true,
      'super_like_note':
          'Votre playlist de Shabbat m\'a donné envie de vous écrire.',
    },
    {
      // Un membre de passage dans une autre ville (Passeport mazl+).
      ..._profile(
        userId: 202,
        name: 'Yaël',
        age: 29,
        city: 'Neuilly-sur-Seine',
        bio:
            'Avocate en droit des affaires, mais jamais loin d\'un sentier de randonnée. Ma challah du vendredi fait l\'unanimité, et je ne dis jamais non à un brunch.',
        denomination: 'Orthodox',
        kashrut: 'Strict',
        shabbat: 'Observant',
        intention: 'marriage',
        verified: true,
        distance: 6,
      ),
      'traveling_city': 'Tel Aviv',
    },
    _profile(
      userId: 203,
      name: 'David',
      age: 33,
      city: 'Lyon',
      gender: 'male',
      bio:
          'Ingénieur logiciel, je cuisine sépharade le dimanche pour toute la famille. Fan de foot et de plages, je cherche une histoire sérieuse, sans prise de tête.',
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
      city: 'Boulogne-Billancourt',
      bio:
          'Architecte, je dessine des maisons et je rêve d\'en habiter une à deux. Je cherche quelqu\'un qui rit facilement et qui aime flâner dans les musées.',
      denomination: 'Laique',
      kashrut: 'Non',
      shabbat: 'Non observant',
      intention: 'open',
      distance: 9,
    ),
    _profile(
      userId: 205,
      name: 'Samuel',
      age: 35,
      city: 'Neuilly-sur-Seine',
      gender: 'male',
      bio:
          'Médecin urgentiste, amateur de jazz et de voyages en Israël. Les week-ends, je cours au bois de Boulogne et je teste de nouveaux restaurants.',
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
      bio:
          'Graphiste indépendante et bénévole dans une association de quartier. J\'aime les marchés du dimanche, les vieux disques et les amitiés qui deviennent autre chose.',
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
      bio:
          'Journaliste, curieuse de tout. Le Shabbat, je déconnecte, je cuisine et je reçois. Je cherche quelqu\'un avec qui refaire le monde autour d\'une grande table.',
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
      bio:
          'Entrepreneuse, ouverte à tout sauf à l\'ennui. Je passe mes week-ends entre Paris et le sud, et j\'adore improviser un voyage de dernière minute.',
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
      bio:
          'Sage-femme, toujours partante pour un café ou une balade. J\'adore mon métier, mes amies et les soirées jeux de société. Je cherche du sérieux et de la bonne humeur.',
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
      city: 'Marseille',
      bio:
          'Dentiste, passionnée de cuisine et de pâtisserie. Famille très présente, Shabbat en tribu. Je rêve d\'une maison pleine de rires et de bruit.',
      denomination: 'Orthodox',
      kashrut: 'Strict',
      shabbat: 'Observant',
      intention: 'marriage',
      distance: 660,
    ),
    _profile(
      userId: 303,
      name: 'Myriam',
      age: 27,
      city: 'Strasbourg',
      bio:
          'En master de psychologie, danseuse le week-end. Je suis sociable, un peu rêveuse, et je prends le temps de connaître les gens avant de m\'engager.',
      denomination: 'Traditionaliste',
      kashrut: 'A la maison',
      shabbat: 'Partiellement',
      intention: 'open',
      distance: 400,
    ),
    _profile(
      userId: 304,
      name: 'Déborah',
      age: 32,
      city: 'Paris',
      bio:
          'Directrice artistique et marathonienne. Je vis entre un atelier et un parc, avec des écouteurs. Je cherche quelqu\'un qui me suive, ou au moins qui m\'attende à l\'arrivée.',
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
      city: 'Nice',
      bio:
          'Psychologue, amatrice de cinéma d\'auteur et de longues conversations. Je passe mes étés à Nice chez ma grand-mère, et je cherche quelqu\'un de calme et de drôle.',
      denomination: 'Massorti',
      kashrut: 'A la maison',
      shabbat: 'Observant',
      intention: 'friends_first',
      distance: 690,
    ),
  ];

  static List<Map<String, dynamic>> _likeProfiles() => [
    _profile(
      userId: 211,
      name: 'Elise',
      age: 28,
      city: 'Boulogne-Billancourt',
      bio:
          'Photographe, je capture les petits instants du quotidien. Je cherche une relation légère au début, mais sincère.',
      denomination: 'Massorti',
      kashrut: 'Non',
      shabbat: 'Non observant',
      intention: 'open',
      distance: 9,
    ),
    _profile(
      userId: 212,
      name: 'Hannah',
      age: 30,
      city: 'Paris',
      bio:
          'Cheffe pâtissière dans une maison réputée. Je travaille tôt, je me couche tôt, et je rêve d\'un homme qui aime goûter mes essais le dimanche matin.',
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
            'picture': DemoPhotos.avatar(p['user_id'] as int),
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
            'picture': DemoPhotos.avatar(profiles[i]['user_id'] as int),
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

  /// Who liked the demo member, in the order of the list.
  static List<Map<String, dynamic>> _likers() => [
    ..._likeProfiles(),
    profileById(matchOnLikeUserId)!,
  ];

  /// `GET /api/likes/received` for a SUBSCRIBER: the complete form, plus the
  /// Super Like and its word. The demo member has no subscription, so the
  /// routes serve [likesReceivedPreview]; this form stays for the tests and
  /// for a subscriber demo.
  static Map<String, dynamic> likesReceived() {
    final likes = [
      for (final (i, p) in _likers().indexed)
        {
          'user_id': p['user_id'],
          'display_name': p['display_name'],
          'picture': DemoPhotos.avatar(p['user_id'] as int),
          'age': p['age'],
          'is_verified': p['is_verified'],
          'liked_at': isoAgo(Duration(hours: 2 + i * 7)),
          'distance': p['distance'],
          'is_super_like': i == 1,
          'note': i == 1 ? 'Ton profil m\'a fait sourire.' : null,
        },
    ];
    return {
      'success': true,
      'count': likes.length,
      'is_premium': true,
      'likes': likes,
    };
  }

  /// `GET /api/likes/received` for a member WITHOUT mazl+, as the server
  /// answers: no identity (no id, no photo, no age), a tiny blurred copy of the
  /// photo or `null` (every third like has none, to show the gradient), the
  /// real count. The first name is sent for the web client; the app ignores it.
  static Map<String, dynamic> likesReceivedPreview() {
    final likes = [
      for (final (i, p) in _likers().indexed)
        {
          'display_name': p['display_name'],
          'is_verified': p['is_verified'],
          'liked_at': isoAgo(Duration(hours: 2 + i * 7)),
          'blurredPhotoUrl': i % 3 == 2
              ? null
              : DemoPhotos.blurred(p['user_id'] as int),
          'is_super_like': i == 1,
        },
    ];
    return {
      'success': true,
      'count': likes.length,
      'is_premium': false,
      'likes': likes,
    };
  }

  static List<Map<String, dynamic>> events() => [
    {
      'id': 1,
      'title': 'Dîner de Shabbat communautaire',
      'description': 'Un dîner convivial pour se rencontrer, ouvert à tous.',
      // Like the events of the TestFlight phase: announced, not open yet.
      'availability': 'coming_soon',
      'notify_requested': false,
      'event_type': 'shabbat_dinner',
      'location': 'Centre communautaire',
      'address': '12 rue de l\'Exemple, Paris',
      'latitude': 48.857,
      'longitude': 2.35,
      'date': isoIn(const Duration(days: 4)),
      'time': '19:30',
      'end_time': '22:30',
      'price': 25,
      'member_price_cents': 1800,
      'currency': 'EUR',
      'max_attendees': 40,
      'attendee_count': 0,
      'image_url':
          'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=1200&q=80',
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
      'image_url':
          'https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=1200&q=80',
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
      'member_price_cents': 1000,
      'currency': 'EUR',
      'max_attendees': 80,
      'attendee_count': 80,
      'image_url':
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
      'is_published': true,
      'user_rsvp_status': 'going',
    },
    {
      'id': 4,
      'title': 'Speed dating autour d\'un café',
      'description':
          'Sept rencontres de sept minutes, dans un café calme. Venez comme vous êtes.',
      'event_type': 'speed_dating',
      'location': 'Café Exemple',
      'address': '3 avenue de la Démo, Neuilly-sur-Seine',
      'latitude': 48.8566,
      'longitude': 2.3522,
      'date': isoIn(const Duration(days: 6)),
      'time': '20:00:00',
      'end_time': '22:30:00',
      'price': 12,
      'currency': 'EUR',
      'max_attendees': 30,
      'attendee_count': 22,
      'image_url':
          'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=1200&q=80',
      'is_published': true,
      'user_rsvp_status': null,
    },
    {
      'id': 5,
      'title': 'Conférence : la Torah et le monde moderne',
      'description':
          'Une soirée de réflexion avec deux invités, suivie d\'un verre et de questions.',
      'event_type': 'lecture',
      'location': 'Maison de la culture',
      'address': '27 boulevard de l\'Exemple, Paris',
      'latitude': 48.8738,
      'longitude': 2.295,
      'date': isoIn(const Duration(days: 13)),
      'time': '19:00:00',
      'end_time': '21:00:00',
      'price': 0,
      'currency': 'EUR',
      'max_attendees': 120,
      'attendee_count': 64,
      'image_url':
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1200&q=80',
      'is_published': true,
      'user_rsvp_status': null,
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
