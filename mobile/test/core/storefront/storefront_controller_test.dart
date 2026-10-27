import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/storefront/storefront_controller.dart';
import 'package:mazl/core/storefront/storefront_repository.dart';

// The repository and the controller: when the app asks the server, in which
// language, what it keeps, and what it shows when the network fails.

String _body({
  String? themeId,
  DateTime? ends,
  DateTime? next,
  String highlight = 'Le plus choisi',
}) => jsonEncode({
  'success': true,
  'data': {
    'serverTime': '2027-02-10T09:00:00Z',
    'products': [
      {
        'productId': 'com.mazl.app.plus.3m',
        'visible': true,
        'sortOrder': 0,
        'featured': true,
        'highlight': highlight,
      },
    ],
    'campaign': themeId == null
        ? null
        : {
            'id': 1,
            'themeId': themeId,
            'accent': '#E5484D',
            'glyph': 'heart',
            'startsAt': '2020-01-01T00:00:00Z',
            'endsAt': ends!.toUtc().toIso8601String(),
            'title': 'La Saint-Valentin approche',
            'subtitle': 'Offrez-vous mazl+',
            'cta': 'Profiter',
            'targets': [],
          },
    'appIcon': themeId == null ? null : 'AppIcon-$themeId',
    'nextChangeAt': next?.toUtc().toIso8601String(),
  },
});

class _FakeRemote implements StorefrontRemote {
  final List<String> languages = [];
  final List<String? Function()> script = [];
  String? Function() fallback = () => null;

  @override
  Future<String?> fetch({required String languageCode}) async {
    languages.add(languageCode);
    return script.isEmpty ? fallback() : script.removeAt(0)();
  }
}

class _MemoryCache implements StorefrontCache {
  String? stored;
  bool failing = false;

  @override
  Future<String?> read() async {
    if (failing) throw Exception('disk');
    return stored;
  }

  @override
  Future<void> write(String body) async {
    if (failing) throw Exception('disk');
    stored = body;
  }
}

void main() {
  late _FakeRemote remote;
  late _MemoryCache cache;
  late StorefrontRepository repository;

  setUp(() {
    remote = _FakeRemote();
    cache = _MemoryCache();
    repository = StorefrontRepository(remote: remote, cache: cache);
  });

  group('repository', () {
    test('keeps the answer it decoded and sends the language', () async {
      remote.fallback = () => _body();
      final fetched = await repository.fetch(languageCode: 'he');
      expect(fetched!.products, hasLength(1));
      expect(remote.languages, ['he']);
      expect(cache.stored, _body());
      expect((await repository.cached())!.products, hasLength(1));
    });

    test('an answer that is not the envelope is not kept', () async {
      cache.stored = _body(highlight: 'ancien');
      remote.fallback = () => '<html>bad gateway</html>';
      expect(await repository.fetch(languageCode: 'fr'), isNull);
      expect(cache.stored, _body(highlight: 'ancien'));
    });

    test('offline: null, and the kept answer is still readable', () async {
      cache.stored = _body(highlight: 'ancien');
      expect(await repository.fetch(languageCode: 'fr'), isNull);
      expect((await repository.cached())!.products.single.highlight, 'ancien');
    });

    test('an unreadable disk is the same as nothing kept', () async {
      cache.failing = true;
      expect(await repository.cached(), isNull);
      remote.fallback = () => _body();
      expect(await repository.fetch(languageCode: 'fr'), isNotNull);
    });
  });

  group('http remote', () {
    test(
      'asks /api/storefront without authentication, with the language',
      () async {
        late http.Request seen;
        final httpRemote = HttpStorefrontRemote(
          baseUrl: 'https://api.example.com',
          client: MockClient((request) async {
            seen = request;
            return http.Response(_body(), 200);
          }),
        );
        expect(await httpRemote.fetch(languageCode: 'ru'), _body());
        expect(seen.method, 'GET');
        expect(seen.url.toString(), 'https://api.example.com/api/storefront');
        expect(seen.headers['Accept-Language'], 'ru');
        expect(seen.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('a refusal, an error and a dead network are all null', () async {
      for (final client in [
        MockClient((_) async => http.Response('{}', 500)),
        MockClient((_) async => http.Response('{}', 404)),
        MockClient((_) async => throw http.ClientException('no route')),
        MockClient((_) => Completer<http.Response>().future),
      ]) {
        final httpRemote = HttpStorefrontRemote(
          client: client,
          timeout: const Duration(milliseconds: 20),
        );
        expect(await httpRemote.fetch(languageCode: 'fr'), isNull);
      }
    });
  });

  group('controller', () {
    testWidgets('shows what is kept at once, then what the server says', (
      tester,
    ) async {
      cache.stored = _body(highlight: 'gardé');
      final server = Completer<String?>();
      remote.script.add(() => null);
      final gate = StorefrontController(
        StorefrontRepository(remote: _GatedRemote(server.future), cache: cache),
      );
      final started = gate.start('fr');
      await tester.pump();
      expect(gate.state.current.products.single.highlight, 'gardé');
      server.complete(_body(highlight: 'frais'));
      await started;
      expect(gate.state.current.products.single.highlight, 'frais');
      gate.dispose();
    });

    testWidgets('offline with nothing kept: the empty storefront', (
      tester,
    ) async {
      final controller = StorefrontController(repository);
      await controller.start('fr');
      expect(controller.state.current.campaign, isNull);
      expect(controller.state.current.products, isEmpty);
      expect(controller.state.current.appIcon, isNull);
      controller.dispose();
    });

    testWidgets('a failed refresh keeps what is shown', (tester) async {
      remote.script.add(() => _body(highlight: 'frais'));
      final controller = StorefrontController(repository);
      await controller.start('fr');
      await controller.refresh(force: true);
      expect(controller.state.current.products.single.highlight, 'frais');
      controller.dispose();
    });

    testWidgets('a return to the foreground does not hammer the server', (
      tester,
    ) async {
      remote.fallback = () => _body();
      final controller = StorefrontController(repository);
      await controller.start('fr');
      await controller.refresh();
      await controller.refresh();
      expect(remote.languages, hasLength(1));
      await tester.pump(const Duration(seconds: 31));
      await controller.refresh();
      expect(remote.languages, hasLength(2));
      controller.dispose();
    });

    testWidgets('a change of language asks again at once, in that language', (
      tester,
    ) async {
      remote.fallback = () => _body();
      final controller = StorefrontController(repository);
      await controller.start('fr');
      await controller.refresh(languageCode: 'es', force: true);
      expect(remote.languages, ['fr', 'es']);
      controller.dispose();
    });

    testWidgets('asks again when the announced change comes', (tester) async {
      final next = clock.now().add(const Duration(hours: 2));
      remote.script
        ..add(() => _body(themeId: 'valentine', ends: next, next: next))
        ..add(() => _body(highlight: 'après'));
      final controller = StorefrontController(repository);
      await controller.start('fr');
      expect(controller.state.current.campaign, isNotNull);
      expect(remote.languages, hasLength(1));

      await tester.pump(const Duration(hours: 2));
      expect(remote.languages, hasLength(1), reason: 'not before the margin');
      await tester.pump(const Duration(seconds: 6));
      expect(remote.languages, hasLength(2));
      expect(controller.state.current.campaign, isNull);
      expect(controller.state.current.products.single.highlight, 'après');
      controller.dispose();
    });

    testWidgets('the campaign is gone at its end even if the server is not '
        'reached', (tester) async {
      final ends = clock.now().add(const Duration(hours: 1));
      remote.script.add(
        () => _body(themeId: 'valentine', ends: ends, next: ends),
      );
      final controller = StorefrontController(repository);
      await controller.start('fr');
      expect(controller.state.current.campaign, isNotNull);
      final tick = controller.state.tick;

      await tester.pump(const Duration(hours: 1, seconds: 6));
      expect(controller.state.tick, greaterThan(tick));
      expect(controller.state.current.campaign, isNull);
      expect(controller.state.current.appIcon, isNull);
      controller.dispose();
    });

    testWidgets('a change the server cache has not caught up with is asked '
        'again, a few times at most', (tester) async {
      final next = clock.now().add(const Duration(minutes: 10));
      remote.fallback = () =>
          _body(themeId: 'valentine', ends: next, next: next);
      final controller = StorefrontController(repository);
      await controller.start('fr');
      await tester.pump(const Duration(minutes: 10, seconds: 6));
      expect(remote.languages, hasLength(2));
      await tester.pump(const Duration(hours: 1));
      // The first ask, the one at the change, then three retries: no more.
      expect(remote.languages, hasLength(5));
      controller.dispose();
    });
  });
}

class _GatedRemote implements StorefrontRemote {
  _GatedRemote(this._answer);

  final Future<String?> _answer;

  @override
  Future<String?> fetch({required String languageCode}) => _answer;
}
