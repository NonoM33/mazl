import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce qui change dans les instantanés, pour ceux qui gardent une copie typée.
enum SnapshotChangeKind { markedStale, dropped, cleared }

class SnapshotChange {
  const SnapshotChange(this.kind, this.keys);

  final SnapshotChangeKind kind;

  /// Les clés touchées ; vide pour [SnapshotChangeKind.cleared] (tout part).
  final List<String> keys;
}

class _Entry {
  _Entry(this.body, this.recordedAt, {this.stale = false});

  final String body;
  final DateTime recordedAt;
  bool stale;
}

/// La dernière réponse connue du serveur pour les écrans principaux : affichée
/// tout de suite à l'ouverture, rafraîchie en arrière-plan (stale-while-
/// revalidate). En mémoire, avec une copie légère dans `shared_preferences`
/// pour survivre au redémarrage. Les corps sont ceux du serveur, tels quels ;
/// chaque lecteur les analyse avec le même code que le réseau.
///
/// Tout est rangé sous le compte connecté : changer de compte ou se déconnecter
/// efface tout, sur le disque aussi.
class ApiSnapshots {
  ApiSnapshots({
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? clock,
    this.persistDelay = const Duration(milliseconds: 400),
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _clock = clock ?? DateTime.now;

  static final ApiSnapshots instance = ApiSnapshots();

  static const String preferencesKey = 'api_snapshots_v1';

  /// Au plus ce nombre de profils d'autres membres gardés (les plus récents).
  static const int maxProfiles = 30;
  static const String _profilePrefix = '/api/profile/';

  /// Au-delà, les plus anciens profils sont oubliés avant d'écrire.
  static const int maxPersistedBytes = 1500000;

  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _clock;
  final Duration persistDelay;

  final Map<String, _Entry> _entries = <String, _Entry>{};
  final List<void Function(SnapshotChange)> _listeners = [];
  String? _owner;
  Timer? _persistTimer;

  /// Le compte dont on garde les réponses ; `null` hors session.
  String? get owner => _owner;

  void addListener(void Function(SnapshotChange) listener) =>
      _listeners.add(listener);
  void removeListener(void Function(SnapshotChange) listener) =>
      _listeners.remove(listener);

  void _emit(SnapshotChange change) {
    for (final listener in List.of(_listeners)) {
      listener(change);
    }
  }

  /// Rattache les instantanés au compte [userId] et recharge ce qui avait été
  /// gardé pour lui. Les instantanés d'un autre compte sont effacés.
  Future<void> bindOwner(String? userId) async {
    if (userId == _owner && userId != null) return;
    if (_owner != null && userId != _owner) await clear();
    _owner = userId;
    if (userId == null || _isMemoryOnly(userId)) return;
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(preferencesKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['owner'] != userId) {
        await prefs.remove(preferencesKey);
        return;
      }
      final entries = decoded['entries'];
      if (entries is! Map<String, dynamic>) return;
      entries.forEach((key, value) {
        if (value is! Map<String, dynamic>) return;
        final body = value['body'];
        final at = DateTime.tryParse('${value['at']}');
        if (body is String && at != null) {
          _entries[key] = _Entry(body, at, stale: value['stale'] == true);
        }
      });
    } on Object catch (error) {
      debugPrint('ApiSnapshots: lecture impossible ($error)');
      _entries.clear();
    }
  }

  /// La session fictive du développement n'écrit rien sur le disque.
  bool _isMemoryOnly(String userId) => userId == '0';

  /// Garde la réponse [body] (200) de [key]. Sans compte, rien n'est gardé.
  void record(String key, String body) {
    if (_owner == null) return;
    _entries[key] = _Entry(body, _clock());
    _schedulePersist();
  }

  String? read(String key) => _entries[key]?.body;

  DateTime? recordedAt(String key) => _entries[key]?.recordedAt;

  /// Vrai quand la réponse a moins de [maxAge] et qu'aucune action de
  /// l'utilisateur ne l'a rendue douteuse depuis.
  bool isFresh(String key, Duration maxAge) {
    final entry = _entries[key];
    if (entry == null || entry.stale) return false;
    return _clock().difference(entry.recordedAt) < maxAge;
  }

  /// Une action (like, message, profil modifié…) rend ces réponses douteuses :
  /// on peut encore les montrer, mais il faut les relire.
  void markStale(Iterable<String> prefixes) {
    final touched = <String>[];
    for (final entry in _entries.entries) {
      if (prefixes.any(entry.key.startsWith)) {
        entry.value.stale = true;
        touched.add(entry.key);
      }
    }
    if (touched.isEmpty) return;
    _schedulePersist();
    _emit(SnapshotChange(SnapshotChangeKind.markedStale, touched));
  }

  /// Ces réponses ne doivent plus jamais être montrées.
  void drop(Iterable<String> prefixes) {
    final gone = _entries.keys
        .where((key) => prefixes.any(key.startsWith))
        .toList();
    if (gone.isEmpty) return;
    gone.forEach(_entries.remove);
    _schedulePersist();
    _emit(SnapshotChange(SnapshotChangeKind.dropped, gone));
  }

  /// Simule un redémarrage de l'app : la mémoire est vidée, le disque reste.
  @visibleForTesting
  void forgetMemoryOnly() {
    _persistTimer?.cancel();
    _persistTimer = null;
    _entries.clear();
    _owner = null;
  }

  /// Déconnexion : tout part, en mémoire et sur le disque.
  Future<void> clear() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    _entries.clear();
    _owner = null;
    _emit(const SnapshotChange(SnapshotChangeKind.cleared, []));
    try {
      final prefs = await _preferences();
      await prefs.remove(preferencesKey);
    } on Object catch (error) {
      debugPrint('ApiSnapshots: effacement impossible ($error)');
    }
  }

  void _schedulePersist() {
    final owner = _owner;
    if (owner == null || _isMemoryOnly(owner)) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(persistDelay, () => unawaited(flush()));
  }

  /// Écrit tout de suite (tests, passage en arrière-plan).
  Future<void> flush() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    final owner = _owner;
    if (owner == null || _isMemoryOnly(owner)) return;
    _trimProfiles();
    final payload = jsonEncode({
      'owner': owner,
      'entries': {
        for (final entry in _entries.entries)
          entry.key: {
            'body': entry.value.body,
            'at': entry.value.recordedAt.toIso8601String(),
            if (entry.value.stale) 'stale': true,
          },
      },
    });
    try {
      final prefs = await _preferences();
      await prefs.setString(preferencesKey, payload);
    } on Object catch (error) {
      debugPrint('ApiSnapshots: écriture impossible ($error)');
    }
  }

  /// Les profils d'autres membres sont les seuls à pousser : on garde les plus
  /// récents, et moins encore si la taille totale devient lourde.
  void _trimProfiles() {
    final profiles =
        _entries.entries
            .where((entry) => entry.key.startsWith(_profilePrefix))
            .toList()
          ..sort((a, b) => b.value.recordedAt.compareTo(a.value.recordedAt));
    for (var i = maxProfiles; i < profiles.length; i++) {
      _entries.remove(profiles[i].key);
    }
    var total = _entries.values.fold<int>(0, (sum, e) => sum + e.body.length);
    for (var i = profiles.length.clamp(0, maxProfiles) - 1; i >= 0; i--) {
      if (total <= maxPersistedBytes) break;
      final removed = _entries.remove(profiles[i].key);
      if (removed != null) total -= removed.body.length;
    }
  }
}
