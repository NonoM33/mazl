import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'consumable_purchases.dart';
import 'credit_models.dart';
import 'credit_pack.dart';
import 'purchase_errors.dart';
import 'store_gateway.dart';
import 'store_products.dart';
import 'subscription_api.dart';
import 'subscription_models.dart';

const String _creditsPath = '/api/credits';
const String _verifyPath = '/api/credits/apple/verify';

/// Boosts et Super Likes : le crédit est tenu par le SERVEUR.
///
/// L'app affiche le solde que le serveur lui dit (`GET /api/credits`, ou le
/// `credits` renvoyé par un swipe, un boost ou une vérification d'achat) et
/// n'accorde jamais rien d'elle-même. Un achat n'ajoute des crédits qu'après
/// `POST /api/credits/apple/verify`.
///
/// Les achats arrivent par le flux UNIQUE de `SubscriptionService`, qui confie
/// les consommables à [handlePurchase] (port [ConsumablePurchaseHandler]).
///
/// Singleton comme [SubscriptionService] ; [CreditsService.create] sert aux
/// tests (faux store, fausse API).
class CreditsService extends ChangeNotifier
    implements ConsumablePurchaseHandler {
  factory CreditsService() => _shared;

  CreditsService.create({
    StoreGateway? gateway,
    SubscriptionApi? api,
    TargetPlatform? platform,
    Duration purchaseSettleTimeout = const Duration(seconds: 45),
  }) : _gateway = gateway,
       _api = api,
       _platform = platform,
       _purchaseSettleTimeout = purchaseSettleTimeout;

  static CreditsService _shared = CreditsService.create();

  /// Remplace le singleton dans un test ; rend l'ancien pour le remettre.
  @visibleForTesting
  static CreditsService debugReplaceShared(CreditsService replacement) {
    final previous = _shared;
    _shared = replacement;
    return previous;
  }

  StoreGateway? _gateway;
  SubscriptionApi? _api;
  final TargetPlatform? _platform;
  final Duration _purchaseSettleTimeout;
  Future<void> Function()? _startPurchaseStream;

  StoreGateway get _store => _gateway ??= InAppPurchaseGateway();
  SubscriptionApi get _backend =>
      _api ??= HttpSubscriptionApi(tokenProvider: () => _token);

  String? _token;
  CreditBalance? _balance;
  _PendingPurchase? _pendingPurchase;
  bool _disposed = false;

  /// Vérifications en cours, par transaction : une transaction livrée deux
  /// fois n'est envoyée qu'une fois au serveur.
  final Map<String, Future<_VerifyOutcome>> _inFlight = {};

  /// Transactions qu'on n'a pas pu vérifier faute de session ou de réseau :
  /// rejouées à la connexion suivante.
  final Map<String, PurchaseDetails> _deferred = {};

  TargetPlatform get _targetPlatform => _platform ?? defaultTargetPlatform;

  // ---------------------------------------------------------------- lecture

  /// Le dernier solde lu auprès du serveur, ou null tant qu'on ne l'a pas.
  CreditBalance? get balance => _balance;

  /// Vrai quand un solde du serveur est connu.
  bool get isLoaded => _balance != null;

  /// Ce que le serveur laisse dépenser maintenant ; 0 tant que le solde est
  /// inconnu (on n'accorde rien sans le serveur).
  int available(CreditKind kind) => _balance?.of(kind).available ?? 0;

  /// Même règle que les abonnements : seul iOS vend.
  bool get canPurchase => canSellOn(_targetPlatform);

  /// Pourquoi l'achat est impossible ici, ou null s'il est possible.
  PurchaseProblem? get unavailablePurchaseProblem =>
      canPurchase ? null : PurchaseProblem.androidSoon;

  // --------------------------------------------------------------- cycle de vie

  /// Branche le démarrage du flux d'achats unique (celui de
  /// `SubscriptionService`) : acheter n'a de sens que s'il écoute.
  void attachPurchaseStream(Future<void> Function() start) {
    _startPurchaseStream = start;
  }

  /// À appeler dès qu'une session est ouverte. Relit le solde, puis rejoue les
  /// achats que la session précédente n'avait pas pu faire vérifier. Ne lève
  /// jamais.
  Future<void> onSignedIn(String? jwtToken) async {
    _token = jwtToken;
    if (jwtToken == null) {
      _setBalance(null);
      return;
    }
    await refresh();
    final retry = List<PurchaseDetails>.of(_deferred.values);
    _deferred.clear();
    await Future.wait(retry.map(_verifyOnce));
  }

  /// À la déconnexion : plus de session, plus de solde.
  void onSignedOut() {
    _token = null;
    _deferred.clear();
    _setBalance(null);
  }

  /// Relit le solde auprès du serveur. Ne lève jamais ; en cas de panne, le
  /// dernier solde connu est conservé.
  Future<void> refresh() async {
    if (_token == null) {
      _setBalance(null);
      return;
    }
    try {
      final reply = await _backend.get(_creditsPath);
      if (reply.statusCode == 401 || reply.statusCode == 403) {
        _setBalance(null);
        return;
      }
      final body = reply.body;
      if (!reply.isOk || body == null) {
        debugPrint('Credits: solde illisible (HTTP ${reply.statusCode})');
        return;
      }
      final parsed = CreditBalance.tryParse(body['credits']);
      if (parsed == null) {
        debugPrint('Credits: réponse inattendue');
        return;
      }
      _setBalance(parsed);
    } on Exception catch (error) {
      debugPrint('Credits: solde non rafraîchi - $error');
    }
  }

  /// Prend le `credits` renvoyé par un swipe, un boost ou une vérification.
  /// Une forme illisible est ignorée : le solde connu est conservé.
  void applyFromServer(Object? credits) {
    final parsed = CreditBalance.tryParse(credits);
    if (parsed == null) {
      if (credits != null) debugPrint('Credits: credits illisible, ignoré');
      return;
    }
    _setBalance(parsed);
  }

  // -------------------------------------------------------------------- packs

  /// Les packs de [kind], du plus petit au plus grand, au prix du store. Vide
  /// si le store est indisponible ou ne connaît aucun de nos produits.
  Future<List<CreditPack>> loadPacks(CreditKind kind) async {
    final wanted = consumableProductsOf(kind);
    try {
      if (!await _store.isAvailable()) return const [];
      final response = await _store.queryProductDetails({
        for (final product in wanted) product.id,
      });
      final error = response.error;
      if (error != null) {
        debugPrint('Credits: produits en erreur - ${error.message}');
      }
      return [
        for (final product in wanted)
          for (final details in response.productDetails)
            if (details.id == product.id)
              CreditPack(product: product, details: details),
      ];
    } on Exception catch (error) {
      debugPrint('Credits: produits indisponibles - $error');
      return const [];
    }
  }

  // -------------------------------------------------------------------- achat

  /// Achète [pack]. Ne lève jamais : l'annulation, l'attente d'approbation et
  /// l'échec sont des issues, pas des exceptions.
  Future<PurchaseResult> buyPack(CreditPack pack) async {
    final unavailable = unavailablePurchaseProblem;
    if (unavailable != null) return PurchaseFailed(unavailable);
    if (_pendingPurchase != null) {
      return const PurchaseFailed(PurchaseProblem.purchaseInProgress);
    }
    final pending = _PendingPurchase(pack.product.id);
    _pendingPurchase = pending;
    try {
      await _startPurchaseStream?.call();
      final started = await _store.buyConsumable(
        PurchaseParam(productDetails: pack.details),
      );
      if (!started) return const PurchaseFailed(PurchaseProblem.generic);
      return await pending.result.future.timeout(
        _purchaseSettleTimeout,
        onTimeout: () => const PurchasePending(),
      );
    } on Exception catch (error) {
      if (isUserCancellation(error)) return const PurchaseCancelled();
      debugPrint('Credits: purchase failed - $error');
      return const PurchaseFailed(PurchaseProblem.generic);
    } finally {
      if (identical(_pendingPurchase, pending)) _pendingPurchase = null;
    }
  }

  /// Un achat de consommable arrivé par le flux d'achats unique.
  @override
  Future<void> handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _resolvePending(purchase.productID, const PurchasePending());
      case PurchaseStatus.canceled:
        _resolvePending(purchase.productID, const PurchaseCancelled());
      case PurchaseStatus.error:
        _resolvePending(
          purchase.productID,
          isUserCancellation(purchase.error)
              ? const PurchaseCancelled()
              : const PurchaseFailed(PurchaseProblem.generic),
        );
        // Une transaction en erreur n'a rien livré : la terminer est sans
        // risque et évite qu'elle bloque un nouvel achat.
        await _complete(purchase);
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final outcome = await _verifyOnce(purchase);
        _resolvePending(purchase.productID, outcome.asPurchaseResult());
    }
  }

  void _resolvePending(String productId, PurchaseResult result) {
    final pending = _pendingPurchase;
    if (pending == null || pending.productId != productId) return;
    if (!pending.result.isCompleted) pending.result.complete(result);
  }

  // ------------------------------------------------------------ vérification

  Future<_VerifyOutcome> _verifyOnce(PurchaseDetails purchase) {
    final key =
        purchase.purchaseID ??
        '${purchase.productID}:${purchase.transactionDate}';
    final running = _inFlight[key];
    if (running != null) return running;
    // Bloc et non flèche : `remove` rend le Future lui-même, et `whenComplete`
    // attendrait un Future qui s'attend lui-même.
    final started = _verify(purchase, key).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = started;
    return started;
  }

  /// Envoie le JWS signé au serveur ; ne lève jamais.
  ///
  /// QUAND TERMINER LA TRANSACTION (`completePurchase`) : les règles des
  /// abonnements.
  ///  - 200 : crédit accordé -> on termine, APRÈS la réponse du serveur ;
  ///  - 409 (achat déjà lié à un autre compte mazl) : refus DÉFINITIF -> on
  ///    termine, sinon l'erreur reviendrait à chaque lancement ;
  ///  - 400 / 422 / 401 / réseau / 5xx : refus ou panne POTENTIELLEMENT
  ///    corrigeable -> on NE termine PAS : la transaction sera rejouée et
  ///    l'utilisateur ne perd pas un achat payé. 401 et les pannes sont aussi
  ///    gardées en mémoire pour être rejouées à la connexion suivante.
  Future<_VerifyOutcome> _verify(PurchaseDetails purchase, String key) async {
    final signed = purchase.verificationData.serverVerificationData;
    try {
      final reply = await _backend.post(_verifyPath, {
        'signedTransaction': signed,
      });
      switch (reply.statusCode) {
        case 200:
          return await _grant(purchase, reply);
        case 409:
          await _complete(purchase);
          return const _VerifyOutcome.refused(
            PurchaseProblem.ownedByAnotherAccount,
          );
        case 400:
          return const _VerifyOutcome.refused(PurchaseProblem.invalidBody);
        case 422:
          return const _VerifyOutcome.refused(
            PurchaseProblem.invalidTransaction,
          );
        case 401:
        case 403:
          _deferred[key] = purchase;
          return const _VerifyOutcome.refused(PurchaseProblem.signInAgain);
        default:
          _deferred[key] = purchase;
          return const _VerifyOutcome.refused(PurchaseProblem.offline);
      }
    } on Exception catch (error) {
      debugPrint('Credits: verification impossible - $error');
      _deferred[key] = purchase;
      return const _VerifyOutcome.refused(PurchaseProblem.offline);
    }
  }

  Future<_VerifyOutcome> _grant(
    PurchaseDetails purchase,
    ApiReply reply,
  ) async {
    final body = reply.body;
    if (body == null || body['success'] != true) {
      debugPrint('Credits: verification reply without success');
      return const _VerifyOutcome.refused(PurchaseProblem.invalidTransaction);
    }
    final credits = CreditBalance.tryParse(body['credits']);
    if (credits != null) _setBalance(credits);
    await _complete(purchase);
    // Le serveur a crédité mais son solde est illisible : on le relit.
    if (credits == null) await refresh();
    return const _VerifyOutcome.granted();
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    if (purchase.purchaseID == null) return;
    try {
      await _store.completePurchase(purchase);
    } on Exception catch (error) {
      // Le crédit est déjà accordé : la transaction sera simplement rejouée,
      // et le serveur répondra « déjà crédité ».
      debugPrint('Credits: transaction non terminée - $error');
    }
  }

  // ------------------------------------------------------------------ interne

  void _setBalance(CreditBalance? balance) {
    _balance = balance;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _PendingPurchase {
  _PendingPurchase(this.productId);

  final String productId;
  final Completer<PurchaseResult> result = Completer<PurchaseResult>();
}

class _VerifyOutcome {
  const _VerifyOutcome.granted() : granted = true, problem = null;

  const _VerifyOutcome.refused(PurchaseProblem this.problem) : granted = false;

  final bool granted;
  final PurchaseProblem? problem;

  PurchaseResult asPurchaseResult() =>
      granted ? const PurchaseSucceeded() : PurchaseFailed(problem!);
}
