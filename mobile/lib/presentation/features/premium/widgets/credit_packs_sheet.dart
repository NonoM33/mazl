import 'package:flutter/material.dart';

import '../../../../core/services/store/credit_models.dart';
import '../../../../core/services/store/credit_pack.dart';
import '../../../../core/services/store/credits_service.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/plus_text.dart';
import '../l10n/plan_price.dart';
import 'plus_widgets.dart';

/// Ce que la feuille rend en se fermant (rien si on l'écarte).
enum CreditPacksOutcome {
  /// Un pack a été acheté et crédité par le serveur.
  purchased,

  /// Le membre veut voir l'offre mazl+.
  discoverPlus,
}

/// La hauteur de deux lignes de pack et de l'espace entre elles : la feuille
/// ne saute pas quand les prix arrivent.
const double _packRowHeight = 64;
const double _packGap = 10;

/// Feuille « packs » : quand le serveur dit qu'il ne reste plus de Super Likes
/// ou de Boosts, les deux packs du type, au prix du store.
///
/// Le fond, la poignée et le 24 px viennent de `showMazlSheet`.
class CreditPacksSheet extends StatefulWidget {
  const CreditPacksSheet({
    super.key,
    required this.kind,
    required this.isSubscriber,
    this.service,
    this.boostMinutes = 30,
  });

  /// Ce qui manque : des Super Likes ou des Boosts.
  final CreditKind kind;

  /// Un abonné ne se voit pas proposer mazl+.
  final bool isSubscriber;

  /// Le service de crédits ; par défaut celui de l'app.
  final CreditsService? service;

  /// Durée d'un Boost annoncée dans le sous-titre.
  final int boostMinutes;

  @override
  State<CreditPacksSheet> createState() => _CreditPacksSheetState();
}

class _CreditPacksSheetState extends State<CreditPacksSheet> {
  late final CreditsService _service = widget.service ?? CreditsService();
  late Future<List<CreditPack>> _packs = _service.loadPacks(widget.kind);
  String? _buyingProductId;
  String? _message;

  void _reload() => setState(() {
    _message = null;
    _packs = _service.loadPacks(widget.kind);
  });

  Future<void> _buy(CreditPack pack) async {
    if (_buyingProductId != null) return;
    setState(() {
      _buyingProductId = pack.product.id;
      _message = null;
    });
    final result = await _service.buyPack(pack);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _buyingProductId = null;
      _message = switch (result) {
        PurchaseSucceeded() || PurchaseCancelled() => null,
        PurchasePending() => l10n.creditsPending,
        PurchaseFailed(:final problem) => purchaseProblemText(l10n, problem),
      };
    });
    if (result is PurchaseSucceeded) {
      Navigator.pop(context, CreditPacksOutcome.purchased);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isBoost = widget.kind == CreditKind.boost;
    final unavailable = _service.unavailablePurchaseProblem;
    final message =
        _message ??
        (unavailable == null ? null : purchaseProblemText(l10n, unavailable));
    return PlusSheetFrame(
      children: [
        SectionLabel(
          isBoost ? l10n.creditsBoostsLabel : l10n.creditsSuperLikesLabel,
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            isBoost ? l10n.creditsBoostsTitle : l10n.creditsSuperLikesTitle,
            style: plusSheetTitleStyle(context),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isBoost
              ? l10n.creditsBoostsSubtitle(widget.boostMinutes)
              : l10n.creditsSuperLikesSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        FutureBuilder<List<CreditPack>>(
          future: _packs,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _loading(l10n);
            }
            final packs = snapshot.data ?? const <CreditPack>[];
            if (packs.isEmpty) return _storeUnavailable(l10n, scheme);
            return _packList(packs, canBuy: unavailable == null);
          },
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (!widget.isSubscriber) ...[
          PlusCtaButton(
            label: l10n.plusDiscover,
            onPressed: () =>
                Navigator.pop(context, CreditPacksOutcome.discoverPlus),
          ),
          const SizedBox(height: 4),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.plusNotNow),
          ),
        ),
      ],
    );
  }

  Widget _loading(AppLocalizations l10n) => SizedBox(
    height: _packRowHeight * 2 + _packGap,
    child: Center(
      child: CircularProgressIndicator(semanticsLabel: l10n.creditsLoading),
    ),
  );

  Widget _storeUnavailable(AppLocalizations l10n, ColorScheme scheme) =>
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.creditsStoreUnavailable,
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: _reload, child: Text(l10n.commonRetry)),
          ],
        ),
      );

  Widget _packList(List<CreditPack> packs, {required bool canBuy}) => Column(
    children: [
      for (final (index, pack) in packs.indexed) ...[
        if (index > 0) const SizedBox(height: _packGap),
        _PackRow(
          pack: pack,
          buying: _buyingProductId == pack.product.id,
          onBuy: canBuy && _buyingProductId == null ? () => _buy(pack) : null,
        ),
      ],
    ],
  );
}

/// Une ligne de pack : la quantité au début, le prix du store à la fin. Se
/// retourne toute seule de droite à gauche.
class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.pack,
    required this.buying,
    required this.onBuy,
  });

  final CreditPack pack;
  final bool buying;

  /// Null : l'achat est impossible pour l'instant (autre achat en cours,
  /// Android).
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final quantity = switch (pack.kind) {
      CreditKind.superLike => l10n.creditsPackSuperLikes(pack.quantity),
      CreditKind.boost => l10n.creditsPackBoosts(pack.quantity),
    };
    final price = planTotalLabel(
      price: pack.price,
      currencyCode: pack.currencyCode,
      locale: l10n.localeName,
    );
    final enabled = onBuy != null;
    final color = enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.creditsPackSemantics(quantity, price),
      excludeSemantics: true,
      onTap: onBuy,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onBuy,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _packRowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      quantity,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (buying)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
