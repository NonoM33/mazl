import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'redaction.dart';

/// Où vont les erreurs que personne n'a rattrapées.
abstract interface class ErrorJournal {
  void record(Object error, StackTrace? stack, {required String source});
}

/// Journal du téléphone : une ligne courte, sans e-mail ni jeton, pour
/// `dart:developer`. Le détail complet part vers Sentry quand le DSN est fourni.
class DeveloperLogJournal implements ErrorJournal {
  const DeveloperLogJournal();

  @override
  void record(Object error, StackTrace? stack, {required String source}) {
    developer.log(
      formatJournalLine(error, source),
      name: 'mazl.error',
      level: 1000,
    );
  }
}

const int _maxMessageLength = 400;

/// `[source] Type: message`, sans donnée personnelle, tronquée.
String formatJournalLine(Object error, String source) {
  final message = redactSensitive('$error');
  final shortMessage = message.length <= _maxMessageLength
      ? message
      : '${message.substring(0, _maxMessageLength)}…';
  return '[$source] ${error.runtimeType}: $shortMessage';
}

/// Branche les deux filets de l'app :
/// - `FlutterError.onError` : erreurs du framework (rendu, gestes) ;
/// - `PlatformDispatcher.onError` : erreurs asynchrones qui échappent à tout
///   `try`, déclarées traitées pour que le moteur n'en ajoute pas une copie
///   brute dans la console.
///
/// À appeler AVANT l'initialisation de Sentry : il s'y chaîne et nous rend la
/// main.
void installGlobalErrorHandlers({
  required ErrorJournal journal,
  bool isDebug = kDebugMode,
}) {
  FlutterError.onError = (details) {
    journal.record(details.exception, details.stack, source: 'flutter');
    if (isDebug) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    journal.record(error, stack, source: 'platform');
    return true;
  };
}
