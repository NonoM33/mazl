import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  // A signed photo URL changes at every fetch: only MazlNetworkImage keys the
  // cache on the stable photo path. A raw CachedNetworkImage reloads the photo
  // on every page change.
  test('no screen draws a network photo outside MazlNetworkImage', () {
    final raw = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.startsWith('lib/core/images/') &&
            RegExp(r'CachedNetworkImage\(|Image\.network\(|(?<![A-Za-z])NetworkImage\(')
                .hasMatch(_code(entity.path)))
          entity.path,
    ];
    expect(raw, isEmpty, reason: 'Use MazlNetworkImage instead.');
  });
}
