import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/observability/quiet_debug_print.dart';

/// ~160 appels à `debugPrint` écrivent des e-mails de membres et des corps
/// d'erreur : en release ils ne doivent plus rien écrire dans la console du
/// téléphone.
void main() {
  late DebugPrintCallback original;

  setUp(() => original = debugPrint);
  tearDown(() => debugPrint = original);

  List<String> capture(void Function() body) {
    final printed = <String>[];
    runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => printed.add(line),
      ),
    );
    return printed;
  }

  test('le canal de capture voit bien ce qu\'on écrit (témoin)', () {
    final printed = capture(() => debugPrintSynchronously('visible'));
    expect(printed, ['visible']);
  });

  test('hors debug, debugPrint n\'écrit plus rien', () {
    silenceDebugPrintOutsideDebug(isDebug: false);

    final printed = capture(() {
      debugPrint('Erreur pour jeanne@example.com : {"token":"abc"}');
      debugPrint('autre ligne', wrapWidth: 20);
    });

    expect(printed, isEmpty);
  });

  test('en debug, debugPrint reste celui de Flutter', () {
    silenceDebugPrintOutsideDebug(isDebug: true);

    expect(identical(debugPrint, original), isTrue);
  });
}
