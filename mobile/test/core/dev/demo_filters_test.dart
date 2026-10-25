import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/matching/discover_filters.dart';

/// La démo répond à /api/discover/filters comme le serveur
/// (docs/launch/V1-CONTRAT.md §2), relue par le VRAI décodeur de l'app.

({int status, Map<String, dynamic> json}) _call(
  String method, {
  Map<String, dynamic> body = const {},
}) {
  final reply = DemoRoutes.respond(
    DemoRequest(method, '/api/discover/filters', const {}, body),
  );
  return (
    status: reply.status,
    json: jsonDecode(reply.json) as Map<String, dynamic>,
  );
}

void main() {
  setUp(DemoStore.reset);

  test('a fresh session has no criterion, and the demo member is mazl+', () {
    final reply = _call('GET');
    expect(reply.status, 200);
    final state = DiscoverFiltersState.fromJson(reply.json);
    expect(state.plus, isTrue);
    expect(state.filters.denominations, isNull);
    expect(state.filters.onlyVerified, isFalse);
  });

  test('a saved criterion is read back; null clears it', () {
    final saved = _call(
      'PUT',
      body: {
        'denominations': ['massorti'],
        'onlyWithPhoto': true,
      },
    );
    expect(saved.status, 200);
    expect(
      DiscoverFilters.fromJson(
        saved.json['filters'] as Map<String, dynamic>,
      ).denominations,
      ['massorti'],
    );

    _call('PUT', body: {'denominations': null});
    final state = DiscoverFiltersState.fromJson(_call('GET').json);
    expect(state.filters.denominations, isNull);
    expect(state.filters.onlyWithPhoto, isTrue);
  });
}
