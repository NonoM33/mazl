import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Sign in with Apple hors des appareils Apple (Android) : Apple ouvre sa page
/// web avec ce Services ID, puis renvoie vers [appleWebRedirectUri], que le
/// serveur retourne à l'app. Vide tant que le Services ID n'existe pas : la
/// connexion Apple reste alors masquée sur Android.
const String appleServicesId = String.fromEnvironment('APPLE_SERVICES_ID');

/// La route du serveur qui reçoit la réponse d'Apple et la rend à l'app.
const String appleWebRedirectUri =
    'https://api.mazl.app/api/auth/apple/android-callback';

bool get appleWebSignInConfigured => appleServicesId.isNotEmpty;

/// Les options web à passer à Sign in with Apple : nulles sur iOS et macOS
/// (connexion native), et tant qu'aucun Services ID n'est configuré.
WebAuthenticationOptions? appleWebAuthenticationOptions({
  required TargetPlatform platform,
  String servicesId = appleServicesId,
}) {
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return null;
  }
  if (servicesId.isEmpty) return null;
  return WebAuthenticationOptions(
    clientId: servicesId,
    redirectUri: Uri.parse(appleWebRedirectUri),
  );
}

/// La réponse web d'Apple est la nôtre seulement si elle rend le `state`
/// envoyé. Sans `state` envoyé (connexion native), rien à comparer.
bool appleWebAnswerIsOurs({required String? sent, required String? received}) =>
    sent == null || (received != null && received == sent);
