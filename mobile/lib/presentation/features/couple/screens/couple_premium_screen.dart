import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/column_app_bar.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../core/services/store/subscription_service.dart';
import '../../../../l10n/l10n.dart';
import '../../premium/l10n/plus_text.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/premium_cards.dart';
import '../widgets/premium_legal.dart';
import '../widgets/premium_pitch.dart';

const _termsUrl = 'https://mazl.app/terms';
const _privacyUrl = 'https://mazl.app/privacy';

/// MAZL Couple, the subscription of the two of them: the argument on the
/// first page, the price and the buttons on the other. A couple that already
/// has it sees instead who pays and when it renews.
class CouplePremiumScreen extends StatefulWidget {
  const CouplePremiumScreen({
    super.key,
    this.subscriptions,
    this.couple,
    this.openUrl,
  });

  /// Injected by tests; the app uses the shared services.
  final SubscriptionService? subscriptions;
  final CoupleService? couple;

  /// Opens a link outside the app; replaceable in the tests.
  final Future<bool> Function(Uri uri)? openUrl;

  @override
  State<CouplePremiumScreen> createState() => _CouplePremiumScreenState();
}

class _CouplePremiumScreenState extends State<CouplePremiumScreen> {
  late final SubscriptionService _subscriptions =
      widget.subscriptions ?? SubscriptionService();
  late final CoupleService _couple = widget.couple ?? CoupleService();

  SubscriptionPlan? _plan;
  bool _planLoading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    if (!_subscriptions.canPurchase) {
      _planLoading = false;
      return;
    }
    final plan = await _subscriptions.loadCouplePlan();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _planLoading = false;
    });
  }

  PricePhase get _phase {
    if (!_subscriptions.canPurchase) return PricePhase.notSold;
    if (_planLoading) return PricePhase.loading;
    return _plan == null ? PricePhase.unavailable : PricePhase.ready;
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _subscribe() async {
    final plan = _plan;
    if (plan == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await _subscriptions.purchase(plan);
      if (!mounted) return;
      final l10n = context.l10n;
      switch (result) {
        case PurchaseSucceeded():
          await _couple.refresh();
          if (!mounted) return;
          // The messenger outlives this page: the confirmation shows after it
          // has closed.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.couplePremiumWelcome)));
          await Navigator.maybePop(context);
        case PurchaseCancelled():
          // Closing the payment sheet is a choice, not an error.
          break;
        case PurchasePending():
          _say(l10n.plusPendingApproval);
        case PurchaseFailed(:final problem):
          showCoupleError(context, purchaseProblemText(l10n, problem));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _subscriptions.restore();
      await _couple.refresh();
      if (!mounted) return;
      final l10n = context.l10n;
      switch (result) {
        case RestoreFound():
          _say(l10n.plusOfferRestored);
        case RestoreNothing():
          _say(l10n.plusOfferNothingFound);
        case RestoreFailed(:final problem):
          showCoupleError(context, purchaseProblemText(l10n, problem));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manage() async {
    final opened = await _subscriptions.manageSubscriptions();
    if (!mounted || opened) return;
    showCoupleError(context, context.l10n.couplePremiumManageFailed);
  }

  Future<void> _open(String url) async {
    var opened = false;
    try {
      opened = await (widget.openUrl ?? _launchExternally)(Uri.parse(url));
    } on PlatformException {
      opened = false;
    }
    if (!mounted || opened) return;
    showCoupleError(context, context.l10n.couplePremiumLinkFailed);
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: ColumnAppBar(
        appBar: AppBar(
          leading: CloseButton(onPressed: () => Navigator.maybePop(context)),
        ),
      ),
      body: ListenableBuilder(
        listenable: _couple,
        builder: (context, _) => FoldSpread(
          laptopVolets: true,
          padding: EdgeInsets.fromLTRB(24, 8, 24, padding.bottom + 24),
          start: const [PremiumPitch()],
          end: _couple.premium.active ? _active() : _offer(),
        ),
      ),
    );
  }

  List<Widget> _offer() {
    final l10n = context.l10n;
    return [
      PremiumPriceCard(phase: _phase, plan: _plan),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _plan == null || _busy ? null : _subscribe,
        child: Text(l10n.couplePremiumSubscribe),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: _busy ? null : _restore,
        style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
        child: Text(l10n.couplePremiumRestore),
      ),
      const SizedBox(height: 12),
      PremiumLegal(
        onOpenTerms: () => _open(_termsUrl),
        onOpenPrivacy: () => _open(_privacyUrl),
      ),
    ];
  }

  List<Widget> _active() {
    final l10n = context.l10n;
    final premium = _couple.premium;
    final mine = premium.paidBy == CouplePayer.me;
    return [
      PremiumActiveCard(
        paidByLine: _paidByLine(premium),
        renewsAt: premium.renewsAt,
      ),
      if (mine) ...[
        const SizedBox(height: 16),
        FilledButton(onPressed: _manage, child: Text(l10n.couplePremiumManage)),
        const SizedBox(height: 12),
        PremiumLegal(
          onOpenTerms: () => _open(_termsUrl),
          onOpenPrivacy: () => _open(_privacyUrl),
        ),
      ],
    ];
  }

  String? _paidByLine(CouplePremium premium) {
    final l10n = context.l10n;
    return switch (premium.paidBy) {
      CouplePayer.me => l10n.couplePremiumPaidByMe,
      CouplePayer.partner => l10n.couplePremiumPaidByPartner(
        _couple.coupleData?.partnerName ?? l10n.coupleSpacePartnerFallback,
      ),
      null => null,
    };
  }
}
