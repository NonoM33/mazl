import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/observability/error_handlers.dart';
import 'package:mazl/core/observability/startup_guard.dart';

class _FakeJournal implements ErrorJournal {
  final List<({Object error, String source})> entries = [];

  @override
  void record(Object error, StackTrace? stack, {required String source}) =>
      entries.add((error: error, source: source));
}

/// Avant `runApp`, un service qui échoue ne doit pas laisser un écran blanc.
void main() {
  late _FakeJournal journal;
  late List<Object> reported;

  setUp(() {
    journal = _FakeJournal();
    reported = [];
  });

  Future<List<String>> run(List<StartupStep> steps) => runStartupSteps(
    steps,
    journal: journal,
    report: (error, stack) => reported.add(error),
  );

  test('exécute les étapes dans l\'ordre', () async {
    final order = <String>[];
    final failed = await run([
      StartupStep('a', () async => order.add('a')),
      StartupStep('b', () async => order.add('b')),
      StartupStep('c', () async => order.add('c')),
    ]);

    expect(order, ['a', 'b', 'c']);
    expect(failed, isEmpty);
    expect(journal.entries, isEmpty);
    expect(reported, isEmpty);
  });

  test('une étape qui échoue n\'empêche pas les suivantes', () async {
    final order = <String>[];
    final failure = StateError('StoreKit indisponible');

    final failed = await run([
      StartupStep('achats', () async => throw failure),
      StartupStep('auth', () async => order.add('auth')),
      StartupStep('push', () async => order.add('push')),
    ]);

    expect(order, ['auth', 'push']);
    expect(failed, ['achats']);
  });

  test('journalise et signale l\'échec avec le nom de l\'étape', () async {
    final failure = StateError('OneSignal indisponible');

    await run([StartupStep('push', () async => throw failure)]);

    expect(journal.entries.single.error, same(failure));
    expect(journal.entries.single.source, 'startup:push');
    expect(reported, [failure]);
  });

  test('rattrape aussi une exception levée avant le premier await', () async {
    final failed = await run([
      StartupStep('sync', () => throw ArgumentError('tout de suite')),
      StartupStep('ok', () async {}),
    ]);

    expect(failed, ['sync']);
  });

  test(
    'un signalement qui échoue lui-même ne casse pas le démarrage',
    () async {
      final order = <String>[];
      final failed = await runStartupSteps(
        [
          StartupStep('a', () async => throw StateError('a')),
          StartupStep('b', () async => order.add('b')),
        ],
        journal: journal,
        report: (error, stack) => throw StateError('Sentry est tombé'),
      );

      expect(failed, ['a']);
      expect(order, ['b']);
    },
  );
}
