import 'dart:io';

import 'l10n/arb_merge.dart';

/// Assemble les fragments de traduction puis génère `AppLocalizations`.
///
///   dart run tool/l10n.dart
Future<void> main() async {
  final files = expectedAssembledFiles(Directory(fragmentsDir));
  for (final entry in files.entries) {
    File('$assembledDir/${entry.key}').writeAsStringSync(entry.value);
  }
  stdout.writeln('${files.length} langues assemblées dans $assembledDir');

  final gen = await Process.start('flutter', [
    'gen-l10n',
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await gen.exitCode;
}
