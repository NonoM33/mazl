import 'demo_fixtures.dart';
import 'demo_store.dart';

/// État de l'espace couple quotidien en démo (docs/couple/ESPACE-COUPLE.md) :
/// humeur, rituels, question du jour, bilan du mois et conciergerie. Contenus
/// SYNTHÉTIQUES (noms et lieux inventés), calés sur l'horloge passée en
/// paramètre pour ne jamais être périmés. Remis à zéro avec le couple.
class DemoCoupleDailyState {
  /// Le jour du couple affiché par la démo (« jour 214 ») : un couple qui
  /// vient de se former en démo montre quand même une histoire en cours.
  static const dayCount = 214;

  /// Les deux membres paient-ils MAZL Couple ? La démo montre tout : oui.
  bool premiumActive = true;

  String? myMood;
  static const partnerMood = 'good';

  // --- Rituels ---

  final List<Map<String, dynamic>> _rituals = [
    {
      'id': 1,
      'kind': 'shabbat',
      'title': 'Shabbat ensemble',
      'weekday': 5,
      'time': null,
      'enabled': true,
      'remind_minutes': 60,
    },
    {
      'id': 2,
      'kind': 'weekly',
      'title': 'Soirée sans écran',
      'weekday': 2,
      'time': '20:00',
      'enabled': false,
      'remind_minutes': 60,
    },
    {
      'id': 3,
      'kind': 'weekly',
      'title': 'Appeler les parents',
      'weekday': 0,
      'time': '18:00',
      'enabled': false,
      'remind_minutes': 30,
    },
  ];

  List<Map<String, dynamic>> rituals() => [
    for (final r in _rituals) {...r},
  ];

  Map<String, dynamic>? ritual(int id) {
    final index = _rituals.indexWhere((r) => r['id'] == id);
    return index < 0 ? null : {..._rituals[index]};
  }

  Map<String, dynamic>? setRitualEnabled(int id, bool enabled) {
    final index = _rituals.indexWhere((r) => r['id'] == id);
    if (index < 0) return null;
    return _rituals[index] = {..._rituals[index], 'enabled': enabled};
  }

  Map<String, dynamic> addRitual(Map<String, dynamic> body) {
    final row = {
      'id': DemoStore.nextId(),
      'kind': 'custom',
      'title': body['title'] ?? '',
      'weekday': body['weekday'],
      'time': body['time'],
      'enabled': body['enabled'] != false,
      'remind_minutes': body['remind_minutes'] ?? 60,
    };
    _rituals.add(row);
    return {...row};
  }

  bool deleteRitual(int id) {
    final before = _rituals.length;
    _rituals.removeWhere((r) => r['id'] == id && r['kind'] == 'custom');
    return _rituals.length != before;
  }

  // --- Question du jour ---

  static const questionId = 214;
  static const questionText =
      "Quel petit geste de l'autre vous a touché cette semaine ?";
  static const _partnerAnswer =
      "Quand tu as préparé le café avant que je me lève, sans rien dire.";

  String? myAnswer;

  Map<String, dynamic> question() => {
    'id': questionId,
    'text': questionText,
    'myAnswer': myAnswer,
    // Retenue tant que l'appelant n'a pas répondu (contrat §5).
    'partnerAnswer': myAnswer == null ? null : _partnerAnswer,
  };

  bool answer(int id, String text) {
    if (id != questionId || text.trim().isEmpty) return false;
    myAnswer = text.trim();
    return true;
  }

  /// Les questions déjà répondues, la plus récente d'abord.
  List<Map<String, dynamic>> history(DateTime now) => [
    {
      'id': 213,
      'text': 'Quel moment de cette semaine voudriez-vous revivre ?',
      'myAnswer': 'Notre dîner improvisé de mardi.',
      'partnerAnswer': 'La promenade après le dîner.',
      'askedOn': _day(now.subtract(const Duration(days: 1))),
    },
    {
      'id': 212,
      'text': 'Qu’est-ce que vous aimeriez apprendre ensemble ?',
      'myAnswer': 'À cuisiner un vrai repas de fête.',
      'partnerAnswer': 'La danse. Même mal.',
      'askedOn': _day(now.subtract(const Duration(days: 2))),
    },
    {
      'id': 210,
      'text': 'Quelle petite habitude à deux ne changeriez-vous jamais ?',
      'myAnswer': 'Le café du dimanche matin.',
      'partnerAnswer': 'Les messages de midi.',
      'askedOn': _day(now.subtract(const Duration(days: 4))),
    },
  ];

  // --- Bilan du mois ---

  static const _partnerScores = {'talk': 4, 'time': 3, 'close': 5};
  Map<String, int>? myScores;

  String period(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> checkin(DateTime now) {
    final mine = myScores;
    return {
      'period': period(now),
      'mine': mine,
      // Le conjoint a déjà répondu : le résumé paraît dès que l'appelant a répondu.
      'partnerDone': true,
      'summary': mine == null ? null : _summary(mine),
    };
  }

  /// `false` si le bilan du mois est déjà rempli (409).
  bool submitCheckin(Map<String, int> scores) {
    if (myScores != null) return false;
    myScores = scores;
    return true;
  }

  Map<String, dynamic> _summary(Map<String, int> mine) {
    var aligned = 0;
    String lowest = 'talk';
    var lowestScore = 6;
    for (final theme in const ['talk', 'time', 'close']) {
      final a = mine[theme]!;
      final b = _partnerScores[theme]!;
      if ((a - b).abs() <= 1) aligned++;
      if (a + b < lowestScore) {
        lowestScore = a + b;
        lowest = theme;
      }
    }
    return {'aligned': aligned, 'lowest': lowest, 'trend': 'down'};
  }

  // --- Conciergerie ---

  final List<_ConciergeRequest> _requests = [];
  bool _seeded = false;

  void _seed(DateTime now) {
    if (_seeded) return;
    _seeded = true;
    final request =
        _ConciergeRequest(
            id: DemoStore.nextId(),
            title: 'Dîner surprise pour vos un an',
            wantedAt: now.add(const Duration(days: 12)),
            city: 'Paris 16e',
            status: 'proposed',
            options: _dinnerOptions,
            now: now,
          )
          ..messages.addAll([
            _message(
              'member',
              'On aimerait un dîner calme et casher pour nos un an, vers Paris 16e, le soir du jour J.',
              now,
            ),
            _message(
              'assistant',
              "Voici trois idées. Choisissez-en une : l'équipe MAZL réserve et vous confirme avant jeudi.",
              now,
            ),
          ]);
    _requests.add(request);
  }

  static const _dinnerOptions = [
    {
      'title': 'Restaurant casher gastronomique',
      'details': 'Paris 16e · salle calme',
      'priceHint': 'environ 120 € pour deux',
    },
    {
      'title': 'Dîner privé à domicile',
      'details': 'Un chef casher chez vous',
      'priceHint': 'environ 180 € pour deux',
    },
    {
      'title': 'Croisière dîner sur la Seine',
      'details': 'Menu casher sur demande',
      'priceHint': 'environ 150 € pour deux',
    },
  ];

  Map<String, dynamic> _message(String role, String text, DateTime at) => {
    'id': DemoStore.nextId(),
    'role': role,
    'authorId': role == 'member' ? DemoFixtures.meId : null,
    'text': text,
    'createdAt': at.toUtc().toIso8601String(),
  };

  List<Map<String, dynamic>> conciergeList(DateTime now) {
    _seed(now);
    return [for (final r in _requests.reversed) r.summary()];
  }

  Map<String, dynamic>? conciergeThread(int id, DateTime now) {
    _seed(now);
    final matching = _requests.where((r) => r.id == id);
    return matching.isEmpty ? null : matching.first.thread();
  }

  /// La demande créée, avec la réponse immédiate de l'assistant.
  Map<String, dynamic> createRequest(Map<String, dynamic> body, DateTime now) {
    _seed(now);
    final text = '${body['text'] ?? ''}'.trim();
    final wanted = DateTime.tryParse('${body['wantedAt'] ?? ''}');
    final request = _ConciergeRequest(
      id: DemoStore.nextId(),
      title: _titleOf(text, body['kind']),
      wantedAt: wanted,
      city: body['city'] as String?,
      status: 'proposed',
      options: _dinnerOptions,
      now: now,
    );
    request.messages.addAll([
      _message('member', text, now),
      _message(
        'assistant',
        "Voici trois idées. Choisissez-en une : l'équipe MAZL réserve et vous confirme.",
        now,
      ),
    ]);
    _requests.add(request);
    return request.thread();
  }

  static String _titleOf(String text, Object? kind) {
    final fallback = switch (kind) {
      'table' => 'Une table pour deux',
      'surprise' => 'Une surprise à organiser',
      'gift' => 'Un cadeau à trouver',
      'weekend' => 'Un week-end à planifier',
      _ => 'Votre demande',
    };
    if (text.isEmpty) return fallback;
    final firstLine = text.split('\n').first;
    return firstLine.length <= 48
        ? firstLine
        : '${firstLine.substring(0, 45)}…';
  }

  Map<String, dynamic>? sendMessage(int id, String text, DateTime now) {
    final request = _find(id);
    if (request == null) return null;
    request.messages
      ..add(_message('member', text.trim(), now))
      ..add(
        _message(
          'assistant',
          'Bien noté. Je tiens compte de ce détail pour les idées.',
          now,
        ),
      );
    request.touch(now);
    return request.thread();
  }

  /// `null` si la demande n'existe pas ; sinon la conversation (inchangée si
  /// l'idée n'existe pas).
  Map<String, dynamic>? choose(int id, int index, DateTime now) {
    final request = _find(id);
    if (request == null) return null;
    if (index < 0 || index >= request.options.length) return request.thread();
    request.status = 'chosen';
    request.chosenIndex = index;
    request.messages.add(
      _message(
        'staff',
        "L'équipe MAZL a bien reçu votre choix : on réserve et on vous confirme ici.",
        now,
      ),
    );
    request.touch(now);
    return request.thread();
  }

  Map<String, dynamic>? cancel(int id, DateTime now) {
    final request = _find(id);
    if (request == null) return null;
    request.status = 'cancelled';
    request.touch(now);
    return request.thread();
  }

  _ConciergeRequest? _find(int id) {
    final matching = _requests.where((r) => r.id == id);
    return matching.isEmpty ? null : matching.first;
  }

  static String _day(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Le jour d'une date d'une demande, au format `AAAA-MM-JJ`.
  static String dayOf(DateTime day) => _day(day);
}

class _ConciergeRequest {
  _ConciergeRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.options,
    required DateTime now,
    this.wantedAt,
    this.city,
  }) : updatedAt = now;

  final int id;
  final String title;
  final DateTime? wantedAt;
  final String? city;
  String status;
  int? chosenIndex;
  DateTime updatedAt;
  final List<Map<String, String>> options;
  final List<Map<String, dynamic>> messages = [];

  void touch(DateTime now) => updatedAt = now;

  /// 1 reçue, 2 idée choisie, 3 réservée par l'équipe.
  int get step => switch (status) {
    'chosen' => 2,
    'booked' || 'closed' => 3,
    _ => 1,
  };

  Map<String, dynamic> summary() => {
    'id': id,
    'title': title,
    'status': status,
    'wantedAt': wantedAt == null ? null : DemoCoupleDailyState.dayOf(wantedAt!),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'step': step,
  };

  Map<String, dynamic> thread() => {
    'request': {
      'id': id,
      'title': title,
      'brief': null,
      'status': status,
      'wantedAt': wantedAt == null
          ? null
          : DemoCoupleDailyState.dayOf(wantedAt!),
      'city': city,
      'options': options,
      'chosenIndex': chosenIndex,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    },
    'messages': [
      for (final m in messages) {...m},
    ],
  };
}
