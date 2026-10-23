import 'demo_couple_fixtures.dart';
import 'demo_fixtures.dart';
import 'demo_store.dart';

enum DemoRequestOutcome { ok, notFound, notPending, forbidden }

class _SentRequest {
  _SentRequest({
    required this.id,
    required this.targetId,
    required this.targetName,
    required this.createdAt,
  });

  final int id;
  final int targetId;
  final String targetName;
  final DateTime createdAt;
  String status = 'pending';
}

/// État du mode couple pendant une session fictive : demandes envoyées, couple
/// et contenus. Remis à zéro avec le reste du [DemoStore].
///
/// Le partenaire fictif accepte tout seul, mais sans minuteur : une demande de
/// plus de [acceptDelay] est acceptée au moment où une route la relit
/// ([settle]). Les horloges sont passées en paramètre, jamais lues ici.
class DemoCoupleState {
  static const acceptDelay = Duration(seconds: 3);

  final List<_SentRequest> _requests = [];
  Map<String, dynamic>? _couple;
  final Set<int> _passed = {};
  final Map<int, DateTime> _saved = {};
  final Map<int, String?> _notes = {};
  final Map<int, DateTime> _registered = {};
  final List<Map<String, dynamic>> _dates = [];
  final List<Map<String, dynamic>> _bucket = [];
  final List<Map<String, dynamic>> _memories = [];

  Map<String, dynamic>? get couple => _couple;
  bool get inCouple => _couple != null;

  Iterable<_SentRequest> get _pending =>
      _requests.where((r) => r.status == 'pending');
  bool get hasPending => _pending.isNotEmpty;
  bool hasPendingWith(int userId) => _pending.any((r) => r.targetId == userId);

  /// Accepte les demandes en attente depuis assez longtemps.
  void settle(DateTime now) {
    if (_couple != null) return;
    for (final request in _pending.toList()) {
      if (now.difference(request.createdAt) < acceptDelay) continue;
      _couple = _coupleWith(request);
      request.status = 'accepted';
      for (final other in _pending) {
        other.status = 'cancelled';
      }
      return;
    }
  }

  Map<String, dynamic> _coupleWith(_SentRequest request) {
    final acceptedAt = request.createdAt.add(acceptDelay).toUtc();
    final matched = DemoFixtures.matches().where(
      (m) => m['id'] == request.targetId,
    );
    return {
      'id': DemoStore.nextId(),
      'partner_id': request.targetId,
      'partner_name': request.targetName,
      'partner_picture': null,
      'started_at': acceptedAt.toIso8601String(),
      'met_on_mazl_at': matched.isEmpty
          ? acceptedAt.toIso8601String()
          : matched.first['matchedAt'],
      'status': 'in_relationship',
    };
  }

  // --- Demandes ---

  Map<String, dynamic> send(int targetId, DateTime now) {
    final request = _SentRequest(
      id: DemoStore.nextId(),
      targetId: targetId,
      targetName: _nameOf(targetId),
      createdAt: now,
    );
    _requests.add(request);
    return {
      'id': request.id,
      'requester_id': DemoFixtures.meId,
      'target_id': request.targetId,
      'status': 'pending',
      'created_at': now.toUtc().toIso8601String(),
      'target_name': request.targetName,
      'target_picture': null,
    };
  }

  static String _nameOf(int userId) =>
      DemoFixtures.profileById(userId)?['display_name'] as String? ??
      'Partenaire';

  List<Map<String, dynamic>> sentViews() => [
    for (final r in _pending)
      {
        'id': r.id,
        'requester_id': DemoFixtures.meId,
        'target_id': r.targetId,
        'status': 'pending',
        'created_at': r.createdAt.toUtc().toIso8601String(),
        'requester_name': DemoFixtures.me()['display_name'],
        'requester_picture': null,
        'target_name': r.targetName,
        'target_picture': null,
      },
  ];

  DemoRequestOutcome cancel(int requestId) {
    final matching = _requests.where((r) => r.id == requestId);
    if (matching.isEmpty) return DemoRequestOutcome.notFound;
    if (matching.first.status != 'pending') {
      return DemoRequestOutcome.notPending;
    }
    matching.first.status = 'cancelled';
    return DemoRequestOutcome.ok;
  }

  /// Seul le destinataire répond : l'utilisateur fictif n'a reçu aucune
  /// demande, donc une demande qu'il a lui-même envoyée est refusée.
  DemoRequestOutcome respond(int requestId) =>
      _requests.any((r) => r.id == requestId)
      ? DemoRequestOutcome.forbidden
      : DemoRequestOutcome.notFound;

  bool end(int coupleId) {
    if (_couple == null || _couple!['id'] != coupleId) return false;
    endCurrent();
    return true;
  }

  void endCurrent() {
    _couple = null;
    _passed.clear();
    _saved.clear();
    _notes.clear();
    _registered.clear();
    _dates.clear();
    _bucket.clear();
    _memories.clear();
  }

  // --- Activités ---

  Map<String, dynamic>? activity(int id) {
    for (final a in DemoCoupleFixtures.activities()) {
      if (a['id'] == id) return a;
    }
    return null;
  }

  List<Map<String, dynamic>> feed(int limit, int offset, String? category) {
    final left = [
      for (final a in DemoCoupleFixtures.activities())
        if (!_passed.contains(a['id']) &&
            !_saved.containsKey(a['id']) &&
            (category == null || a['category'] == category))
          a,
    ];
    return left.skip(offset).take(limit).toList();
  }

  void save(int id, String? notes, DateTime now) {
    _saved.putIfAbsent(id, () => now);
    if (notes != null) _notes[id] = notes;
  }

  void pass(int id) => _passed.add(id);
  bool removeSaved(int id) => _saved.remove(id) != null;

  List<Map<String, dynamic>> saved() {
    final entries = _saved.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        if (activity(e.key) != null)
          {
            ...activity(e.key)!,
            'saved_at': e.value.toUtc().toIso8601String(),
            'user_notes': _notes[e.key],
          },
    ];
  }

  // --- Évènements ---

  Map<String, dynamic>? event(int id, DateTime now) {
    for (final e in DemoCoupleFixtures.events(now)) {
      if (e['id'] == id) return _withCount(e);
    }
    return null;
  }

  Map<String, dynamic> _withCount(Map<String, dynamic> e) => {
    ...e,
    'current_couples':
        (e['current_couples'] as int) +
        (_registered.containsKey(e['id']) ? 1 : 0),
  };

  List<Map<String, dynamic>> events(
    DateTime now,
    int limit,
    int offset,
    String? category,
  ) => [
    for (final e in DemoCoupleFixtures.events(now))
      if (category == null || e['category'] == category) _withCount(e),
  ].skip(offset).take(limit).toList();

  /// `null` si l'évènement est complet.
  Map<String, dynamic>? register(Map<String, dynamic> event, DateTime now) {
    final id = event['id'] as int;
    final max = event['max_couples'] as int?;
    if (!_registered.containsKey(id) &&
        max != null &&
        (event['current_couples'] as int) >= max) {
      return null;
    }
    _registered.putIfAbsent(id, () => now);
    return {
      'id': DemoStore.nextId(),
      'couple_id': _couple!['id'],
      'event_id': id,
      'status': 'registered',
      'registered_at': _registered[id]!.toUtc().toIso8601String(),
      'cancelled_at': null,
    };
  }

  void unregister(int id) => _registered.remove(id);

  List<Map<String, dynamic>> registeredEvents(DateTime now) => [
    for (final e in DemoCoupleFixtures.events(now))
      if (_registered.containsKey(e['id']))
        {
          ..._withCount(e),
          'registered_at': _registered[e['id']]!.toUtc().toIso8601String(),
          'registration_status': 'registered',
        },
  ];

  // --- Dates, projets, souvenirs, statistiques ---

  List<Map<String, dynamic>> dates() => List.of(_dates);
  List<Map<String, dynamic>> bucketList() => List.of(_bucket);
  List<Map<String, dynamic>> memories() => List.of(_memories);

  Map<String, dynamic> addDate(Map<String, dynamic> body, DateTime now) =>
      _add(_dates, {
        'title': body['title'],
        'date': body['date'],
        'type': body['type'],
        'is_recurring': body['isRecurring'] ?? true,
        'remind_days_before': body['remindDaysBefore'] ?? 7,
        'notes': body['notes'],
      }, now);

  Map<String, dynamic> addBucketItem(Map<String, dynamic> body, DateTime now) =>
      _add(_bucket, {
        'title': body['title'],
        'description': body['description'],
        'category': body['category'],
        'is_completed': false,
        'completed_at': null,
        'target_date': body['targetDate'],
        'priority': 0,
      }, now);

  Map<String, dynamic> addMemory(Map<String, dynamic> body, DateTime now) =>
      _add(_memories, {
        'type': body['type'],
        'title': body['title'],
        'content': body['content'],
        'image_url': body['imageUrl'],
        'memory_date': body['memoryDate'],
        'location': body['location'],
        'tags': const <Object>[],
        'is_favorite': false,
        'created_by': DemoFixtures.meId,
      }, now);

  Map<String, dynamic> _add(
    List<Map<String, dynamic>> into,
    Map<String, dynamic> fields,
    DateTime now,
  ) {
    final row = {
      'id': DemoStore.nextId(),
      'couple_id': _couple!['id'],
      ...fields,
      'created_at': now.toUtc().toIso8601String(),
    };
    into.insert(0, row);
    return row;
  }

  /// `null` si l'élément n'existe pas.
  Map<String, dynamic>? completeBucketItem(int id, DateTime now) {
    final index = _bucket.indexWhere((i) => i['id'] == id);
    if (index < 0) return null;
    return _bucket[index] = {
      ..._bucket[index],
      'is_completed': true,
      'completed_at': now.toUtc().toIso8601String(),
    };
  }

  /// Forme du serveur (`getCoupleStats`) plus les deux compteurs que lit
  /// l'écran « Notre espace ».
  Map<String, dynamic> stats() => {
    'total_bookings': 0,
    'saved_activities': _saved.length,
    'events_registered': _registered.length,
    'memories_count': _memories.length,
    'bucket_completed': _bucket.where((i) => i['is_completed'] == true).length,
    'bucket_total': _bucket.length,
    'activitiesDone': _bucket.where((i) => i['is_completed'] == true).length,
    'eventsAttended': _registered.length,
  };
}
