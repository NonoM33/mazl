import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Flutter's AnimationController and flutter_animate ignore the iPhone's
// « Réduire les animations » on their own (docs/design/MOUVEMENT.md §1): every
// file that starts an animation must say how it behaves under the setting, by
// reading MazlMotion.reduced or MediaQuery.disableAnimations. This test sweeps
// lib/ and refuses a new file that animates without doing so.

/// Starts an animation that does not stop by itself under the setting.
final _animates = RegExp(
  r'AnimationController\(|\.animate\(|animateToPage\(|animateTo\(|elasticOut',
);

/// Reads the setting.
final _readsSetting = RegExp(r'MazlMotion\.reduced|disableAnimations');

/// Files known to animate without reading the setting yet. This list can only
/// SHRINK: a file that becomes compliant must leave it (the test below fails
/// otherwise), and no file is added to it.
const _knownNonCompliant = <String>{
  // Fixed in a parallel branch of the reduced-motion work (Discover screens).
  'lib/presentation/features/matching/screens/daily_picks_screen.dart',
};

String _code(File file) => file
    .readAsLinesSync()
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

List<String> _animatingFilesIgnoringTheSetting() {
  final offenders = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final code = _code(entity);
    if (_animates.hasMatch(code) && !_readsSetting.hasMatch(code)) {
      offenders.add(entity.path);
    }
  }
  return offenders..sort();
}

void main() {
  test('every file that animates reads the Reduce Motion setting', () {
    final offenders = _animatingFilesIgnoringTheSetting()
        .where((path) => !_knownNonCompliant.contains(path))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'These files start an animation without MazlMotion.reduced or '
          'disableAnimations. Decide what they do under « Réduire les '
          'animations » (docs/design/MOUVEMENT.md §1).',
    );
  });

  test('the list of known exceptions only shrinks', () {
    final stillIgnoring = _animatingFilesIgnoringTheSetting().toSet();
    final fixed = _knownNonCompliant.where(
      (path) => !stillIgnoring.contains(path),
    );

    expect(
      fixed,
      isEmpty,
      reason:
          'These files now read the setting: remove them from '
          '_knownNonCompliant.',
    );
  });

  test('the sweep sees the files it should', () {
    // Guards the guard: a moved lib/ or a broken pattern would pass silently.
    final animating = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => _animates.hasMatch(_code(f)))
        .map((f) => f.path)
        .toSet();

    expect(
      animating,
      containsAll(<String>[
        'lib/presentation/features/auth/screens/email_auth_screen.dart',
        'lib/presentation/features/couple/widgets/anniversary_widget.dart',
        'lib/presentation/features/profile/widgets/profile_view/profile_photo_gallery.dart',
      ]),
    );
  });

  test('the patterns catch each way of starting an animation', () {
    for (final snippet in [
      'AnimationController(vsync: this)',
      'Text("a").animate().fadeIn()',
      'controller.animateToPage(1)',
      'tabController.animateTo(0)',
      'curve: Curves.elasticOut',
    ]) {
      expect(_animates.hasMatch(snippet), isTrue, reason: snippet);
    }
    expect(_readsSetting.hasMatch('MazlMotion.reduced(context)'), isTrue);
    expect(_readsSetting.hasMatch('MediaQuery.disableAnimationsOf(c)'), isTrue);
    expect(_animates.hasMatch('final animated = true;'), isFalse);
  });
}
