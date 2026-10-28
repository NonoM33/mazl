import 'package:flutter/foundation.dart';

/// Client OAuth de l'app iOS : il signe les jetons de l'iPhone.
const String googleIosClientId =
    '114247778518-kpbe9qm21122c1kken6m1d3o23fmtqre.apps.googleusercontent.com';

/// Client OAuth web (GOOGLE_CLIENT_ID du serveur). Android ne rend un idToken
/// que si on lui donne ce client comme destinataire du jeton.
const String googleWebClientId =
    '114247778518-1bkjnb262ljaklg7pie1som74tedpt79.apps.googleusercontent.com';

/// Les deux identifiants à passer à `GoogleSignIn`, selon la plateforme.
({String? clientId, String? serverClientId}) googleClientIdsFor(
  TargetPlatform platform,
) => switch (platform) {
  TargetPlatform.android => (clientId: null, serverClientId: googleWebClientId),
  _ => (clientId: googleIosClientId, serverClientId: null),
};
