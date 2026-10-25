import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/observability/error_handlers.dart';

class _FakeJournal implements ErrorJournal {
  final List<({Object error, StackTrace? stack, String source})> entries = [];

  @override
  void record(Object error, StackTrace? stack, {required String source}) =>
      entries.add((error: error, stack: stack, source: source));
}

/// Une erreur qui échappe à tout `try` ne doit ni disparaître en silence ni
/// recracher son texte brut dans la console du téléphone.
void main() {
  late FlutterExceptionHandler? savedFlutterOnError;
  late FlutterExceptionHandler savedPresentError;
  late ErrorCallback? savedPlatformOnError;
  late _FakeJournal journal;

  setUp(() {
    savedFlutterOnError = FlutterError.onError;
    savedPresentError = FlutterError.presentError;
    savedPlatformOnError = PlatformDispatcher.instance.onError;
    journal = _FakeJournal();
  });

  tearDown(() {
    FlutterError.onError = savedFlutterOnError;
    FlutterError.presentError = savedPresentError;
    PlatformDispatcher.instance.onError = savedPlatformOnError;
  });

  group('FlutterError.onError', () {
    test('journalise l\'erreur du framework', () {
      installGlobalErrorHandlers(journal: journal, isDebug: false);
      final error = StateError('rendu cassé');

      FlutterError.onError!(
        FlutterErrorDetails(exception: error, stack: StackTrace.current),
      );

      expect(journal.entries, hasLength(1));
      expect(journal.entries.single.error, same(error));
      expect(journal.entries.single.source, 'flutter');
      expect(journal.entries.single.stack, isNotNull);
    });

    test('en release, n\'affiche pas le détail brut dans la console', () {
      var presented = 0;
      FlutterError.presentError = (_) => presented++;
      installGlobalErrorHandlers(journal: journal, isDebug: false);

      FlutterError.onError!(FlutterErrorDetails(exception: StateError('x')));

      expect(presented, 0);
    });

    test('en debug, garde l\'affichage habituel pour le développeur', () {
      var presented = 0;
      FlutterError.presentError = (_) => presented++;
      installGlobalErrorHandlers(journal: journal, isDebug: true);

      FlutterError.onError!(FlutterErrorDetails(exception: StateError('x')));

      expect(presented, 1);
      expect(journal.entries, hasLength(1));
    });
  });

  group('PlatformDispatcher.onError', () {
    test(
      'journalise l\'erreur asynchrone non rattrapée et la déclare traitée',
      () {
        installGlobalErrorHandlers(journal: journal, isDebug: false);
        final error = StateError('future perdue');

        final handled = PlatformDispatcher.instance.onError!(
          error,
          StackTrace.current,
        );

        expect(handled, isTrue);
        expect(journal.entries.single.error, same(error));
        expect(journal.entries.single.source, 'platform');
      },
    );
  });

  group('formatJournalLine', () {
    test('donne le type, la provenance et le message', () {
      final line = formatJournalLine(StateError('rendu cassé'), 'flutter');
      expect(line, contains('flutter'));
      expect(line, contains('StateError'));
      expect(line, contains('rendu cassé'));
    });

    test('ne contient ni e-mail ni jeton', () {
      final line = formatJournalLine(
        Exception(
          'refus pour jeanne@example.com, Authorization: Bearer abc123def456',
        ),
        'platform',
      );
      expect(line, isNot(contains('jeanne')));
      expect(line, isNot(contains('abc123def456')));
    });

    test('reste courte même pour un message énorme', () {
      final line = formatJournalLine(Exception('x ' * 5000), 'flutter');
      expect(line.length, lessThan(600));
    });
  });
}
