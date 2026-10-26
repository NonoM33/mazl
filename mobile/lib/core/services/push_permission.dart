/// Demande l'autorisation des notifications au plus une fois, et ne renvoie
/// jamais vers les Réglages : un refus est respecté. (Un renvoi vers les
/// Réglages à chaque lancement dès que la personne avait refusé était une
/// erreur de l'ancien fournisseur de push.)
Future<void> askPushPermissionIfNeeded({
  required Future<bool> Function() canRequest,
  required Future<bool> Function(bool fallbackToSettings) request,
}) async {
  if (!await canRequest()) return;
  await request(false);
}
