import 'dart:async';

import 'error_handlers.dart';

/// Une étape du démarrage (service à initialiser avant `runApp`).
class StartupStep {
  const StartupStep(this.name, this.run);

  final String name;
  final Future<void> Function() run;
}

typedef StartupFailureReporter =
    FutureOr<void> Function(Object error, StackTrace stack);

/// Exécute les étapes dans l'ordre. Une étape qui échoue est journalisée et
/// signalée, puis le démarrage continue : l'app s'ouvre quand même au lieu de
/// rester sur un écran blanc. Renvoie les noms des étapes en échec.
Future<List<String>> runStartupSteps(
  List<StartupStep> steps, {
  required ErrorJournal journal,
  required StartupFailureReporter report,
}) async {
  final failed = <String>[];
  for (final step in steps) {
    try {
      await step.run();
    } on Object catch (error, stack) {
      failed.add(step.name);
      journal.record(error, stack, source: 'startup:${step.name}');
      await _reportSafely(report, error, stack, journal);
    }
  }
  return failed;
}

Future<void> _reportSafely(
  StartupFailureReporter report,
  Object error,
  StackTrace stack,
  ErrorJournal journal,
) async {
  try {
    await report(error, stack);
  } on Object catch (reportError, reportStack) {
    journal.record(reportError, reportStack, source: 'startup:report');
  }
}
