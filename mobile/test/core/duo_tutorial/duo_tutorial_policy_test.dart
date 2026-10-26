import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_policy.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';

class _MemoryStore implements DuoTutorialStore {
  bool seen = false;
  int writes = 0;

  @override
  Future<bool> hasBeenSeen() async => seen;

  @override
  Future<void> markSeen() async {
    writes++;
    seen = true;
  }
}

/// Le tutoriel se lance UNE fois, au démarrage, sur le Duo et nulle part ailleurs.
void main() {
  group('quand le montrer', () {
    test('sur le Duo, la première fois : oui', () {
      for (final pose in DuoPose.values) {
        expect(
          shouldShowDuoTutorial(fold: pose.foldState, alreadySeen: false),
          isTrue,
          reason: 'le Duo, ${pose.name}',
        );
      }
    });

    test('sur le Duo, une fois vu : non', () {
      for (final pose in DuoPose.values) {
        expect(
          shouldShowDuoTutorial(fold: pose.foldState, alreadySeen: true),
          isFalse,
          reason: pose.name,
        );
      }
    });

    test('sur tout autre iPhone : jamais, même la première fois', () {
      expect(
        shouldShowDuoTutorial(fold: FoldState.unknown, alreadySeen: false),
        isFalse,
      );
    });
  });

  group('l\'indicateur « déjà vu »', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('absent au départ, présent après markSeen, et il reste', () async {
      final store = SharedPreferencesDuoTutorialStore();
      expect(await store.hasBeenSeen(), isFalse);
      await store.markSeen();
      expect(await SharedPreferencesDuoTutorialStore().hasBeenSeen(), isTrue);
    });

    test('se lit dans la clé nommée, pas dans une autre', () async {
      SharedPreferences.setMockInitialValues({'duo_tutorial_seen': true});
      expect(await SharedPreferencesDuoTutorialStore().hasBeenSeen(), isTrue);
      SharedPreferences.setMockInitialValues({'autre': true});
      expect(await SharedPreferencesDuoTutorialStore().hasBeenSeen(), isFalse);
    });
  });

  group('decideDuoTutorialLaunch : au démarrage', () {
    test(
      'sur le Duo, première fois : on le lance et on note qu\'il a été montré',
      () async {
        final store = _MemoryStore();
        final show = await decideDuoTutorialLaunch(
          fold: DuoPose.closed.foldState,
          store: store,
        );
        expect(show, isTrue);
        expect(
          store.seen,
          isTrue,
          reason: 'un second démarrage ne le relance pas',
        );
      },
    );

    test('un second démarrage ne le relance pas', () async {
      final store = _MemoryStore();
      await decideDuoTutorialLaunch(
        fold: DuoPose.closed.foldState,
        store: store,
      );
      final again = await decideDuoTutorialLaunch(
        fold: DuoPose.closed.foldState,
        store: store,
      );
      expect(again, isFalse);
      expect(store.writes, 1);
    });

    test('sur un autre iPhone : pas de tutoriel, rien n\'est noté', () async {
      final store = _MemoryStore();
      final show = await decideDuoTutorialLaunch(
        fold: FoldState.unknown,
        store: store,
      );
      expect(show, isFalse);
      expect(store.seen, isFalse, reason: 'le Duo viendra peut-être plus tard');
      expect(store.writes, 0);
    });

    test('une lecture qui échoue ne bloque pas le démarrage', () async {
      final show = await decideDuoTutorialLaunch(
        fold: DuoPose.closed.foldState,
        store: _FailingStore(),
      );
      expect(show, isFalse);
    });
  });

  group('l\'entrée des Réglages', () {
    test('visible sur le Duo seulement', () {
      expect(showDuoTutorialInSettings(DuoPose.closed.foldState), isTrue);
      expect(
        showDuoTutorialInSettings(DuoPose.openLandscape.foldState),
        isTrue,
      );
      expect(showDuoTutorialInSettings(FoldState.unknown), isFalse);
    });
  });

  group('le chemin du tutoriel', () {
    test('sans suite : on revient d\'où l\'on vient (Réglages)', () {
      expect(duoTutorialLocation(), '/duo-tutorial');
    });

    test('avec une suite : la route à rejoindre ensuite, encodée', () {
      expect(
        duoTutorialLocation(next: '/discover'),
        '/duo-tutorial?next=%2Fdiscover',
      );
    });

    test('la suite ne peut être qu\'une route de l\'app', () {
      expect(safeDuoTutorialNext('/discover'), '/discover');
      expect(safeDuoTutorialNext('/onboarding'), '/onboarding');
      expect(safeDuoTutorialNext('//evil.example'), isNull);
      expect(safeDuoTutorialNext('https://evil.example'), isNull);
      expect(safeDuoTutorialNext(''), isNull);
      expect(safeDuoTutorialNext(null), isNull);
    });
  });
}

class _FailingStore implements DuoTutorialStore {
  @override
  Future<bool> hasBeenSeen() async => throw StateError('disque plein');

  @override
  Future<void> markSeen() async => throw StateError('disque plein');
}
