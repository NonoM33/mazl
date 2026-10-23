/// Demande l'autorisation des notifications au plus une fois, et ne renvoie
/// jamais vers les Réglages : un refus est respecté. (Avec
/// `fallbackToSettings: true`, OneSignal affichait « Open Settings » à chaque
/// lancement dès que la personne avait refusé.)
Future<void> askPushPermissionIfNeeded({
  required Future<bool> Function() canRequest,
  required Future<bool> Function(bool fallbackToSettings) request,
}) async {
  if (!await canRequest()) return;
  await request(false);
}
