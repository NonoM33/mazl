import 'credits_service.dart';
import 'subscription_service.dart';

/// Les services du store qui suivent la session : l'abonnement et le solde de
/// crédits. Un seul endroit les prévient de la connexion et de la déconnexion,
/// pour qu'aucun des deux ne soit oublié.
class StoreSession {
  StoreSession({SubscriptionService? subscriptions, CreditsService? credits})
    : _subscriptions = subscriptions,
      _credits = credits;

  final SubscriptionService? _subscriptions;
  final CreditsService? _credits;

  // Résolus à l'appel : un test peut remplacer le singleton après coup.
  SubscriptionService get _subscriptionService =>
      _subscriptions ?? SubscriptionService();
  CreditsService get _creditsService => _credits ?? CreditsService();

  /// À appeler dès qu'une session est ouverte (connexion ou session
  /// restaurée) : relit l'abonnement et le solde, et rejoue les achats que la
  /// session précédente n'avait pas pu faire vérifier. Ne lève jamais.
  Future<void> onSignedIn(String? jwtToken) => Future.wait([
    _subscriptionService.onSignedIn(jwtToken),
    _creditsService.onSignedIn(jwtToken),
  ]);

  /// À la déconnexion : plus de session, plus de droit, plus de solde.
  void onSignedOut() {
    _subscriptionService.onSignedOut();
    _creditsService.onSignedOut();
  }
}
