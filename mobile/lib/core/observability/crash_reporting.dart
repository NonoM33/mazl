import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';
import 'redaction.dart';

/// Réglage du signalement des plantages, fixé à la compilation :
///
/// ```sh
/// flutter build ios --release --dart-define=SENTRY_DSN=https://...
/// ```
///
/// Sans `SENTRY_DSN`, rien n'est initialisé : aucun envoi, aucun appel réseau.
class CrashReportingConfig {
  const CrashReportingConfig({
    required this.dsn,
    required this.environment,
    this.release,
  });

  const CrashReportingConfig.fromEnvironment()
    : dsn = const String.fromEnvironment('SENTRY_DSN'),
      environment = Env.appEnv,
      release = const String.fromEnvironment('SENTRY_RELEASE') == ''
          ? null
          : const String.fromEnvironment('SENTRY_RELEASE');

  final String dsn;
  final String environment;

  /// `null` : Sentry la déduit de l'app (`com.mazl.app@version+build`).
  final String? release;

  bool get isEnabled => dsn.trim().isNotEmpty;
}

/// `SentryFlutter.init`, remplaçable dans les tests.
typedef SentryInitializer =
    Future<void> Function(FlutterOptionsConfiguration configure);

/// Démarre Sentry si le DSN est fourni. Renvoie `true` si le signalement est
/// actif. À appeler APRÈS l'installation des gestionnaires d'erreurs de l'app :
/// Sentry s'y chaîne et leur rend la main.
Future<bool> startCrashReporting(
  CrashReportingConfig config, {
  SentryInitializer init = SentryFlutter.init,
}) async {
  if (!config.isEnabled) return false;
  await init((options) => applyCrashReportingOptions(options, config));
  return true;
}

/// Les options : le minimum nécessaire pour comprendre un plantage.
void applyCrashReportingOptions(
  SentryFlutterOptions options,
  CrashReportingConfig config,
) {
  options
    ..dsn = config.dsn.trim()
    ..environment = config.environment
    ..release = config.release
    ..sendDefaultPii = false
    ..attachScreenshot = false
    ..attachViewHierarchy = false
    ..maxRequestBodySize = MaxRequestBodySize.never
    ..captureFailedRequests = false
    ..enableAutoSessionTracking = false
    ..enableUserInteractionBreadcrumbs = false
    ..tracesSampleRate = null
    ..beforeSend = scrubCrashEvent
    ..beforeBreadcrumb = scrubCrashBreadcrumb;
}

/// Dernier filtre avant l'envoi : plus d'utilisateur, de requête ni de nom de
/// machine, et plus aucune adresse e-mail ni aucun jeton dans les textes.
FutureOr<SentryEvent?> scrubCrashEvent(SentryEvent event, Hint hint) {
  event
    ..user = null
    ..request = null
    ..serverName = null
    ..message = _scrubMessage(event.message)
    ..breadcrumbs = event.breadcrumbs
        ?.map((crumb) => _scrubBreadcrumb(crumb))
        .toList();
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    exception.value = redactSensitiveOrNull(exception.value);
  }
  for (final key in event.contexts.keys.toList()) {
    final value = event.contexts[key];
    if (value is Map || value is String) {
      event.contexts[key] = _scrubValue(value);
    }
  }
  event.contexts.device?.name = null;
  _scrubExtra(event);
  return event;
}

/// `extra` est déprécié au profit des contextes, mais il est toujours envoyé
/// tel quel si quelqu'un le remplit un jour : on le filtre quand même.
void _scrubExtra(SentryEvent event) {
  // ignore: deprecated_member_use
  event.extra = _scrubMap(event.extra);
}

Breadcrumb? scrubCrashBreadcrumb(Breadcrumb? breadcrumb, Hint hint) =>
    breadcrumb == null ? null : _scrubBreadcrumb(breadcrumb);

Breadcrumb _scrubBreadcrumb(Breadcrumb crumb) => crumb
  ..message = redactSensitiveOrNull(crumb.message)
  ..data = _scrubMap(crumb.data);

SentryMessage? _scrubMessage(SentryMessage? message) {
  if (message == null) return null;
  return SentryMessage(
    redactSensitive(message.formatted),
    template: redactSensitiveOrNull(message.template),
    params: message.params?.map(_scrubValue).toList(),
  );
}

Map<String, dynamic>? _scrubMap(Map<String, dynamic>? map) => map == null
    ? null
    : <String, dynamic>{
        for (final entry in map.entries) entry.key: _scrubValue(entry.value),
      };

dynamic _scrubValue(dynamic value) => switch (value) {
  final String text => redactSensitive(text),
  final Map<dynamic, dynamic> map => <dynamic, dynamic>{
    for (final entry in map.entries) entry.key: _scrubValue(entry.value),
  },
  final List<dynamic> list => list.map(_scrubValue).toList(),
  _ => value,
};
