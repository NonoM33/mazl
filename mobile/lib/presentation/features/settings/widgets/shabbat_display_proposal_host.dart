import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/layout/fold_state.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/rest_display_content.dart';
import '../../../../core/services/shabbat_display_proposal.dart';
import '../../../../l10n/l10n.dart';
import '../shabbat_place.dart';

/// Proposes the Shabbat display, once, in the hours before candle lighting,
/// when the foldable iPhone stands like a tent. A discreet card at the bottom
/// of the page; the rest of the app stays where it is.
///
/// Nothing is asked of a phone that is not that one: the place of the member
/// is not even read.
class ShabbatDisplayProposalHost extends StatefulWidget {
  const ShabbatDisplayProposalHost({
    super.key,
    required this.onLaunch,
    required this.child,
    this.clock,
    this.placeLoader,
    this.dismissals = const PreferencesProposalDismissals(),
  });

  /// Opens the display.
  final VoidCallback onLaunch;
  final Widget child;

  /// L'heure qu'il est ; injectée par les tests.
  final DateTime Function()? clock;

  /// Reads the member's place; the profile by default.
  final Future<ShabbatPlace> Function()? placeLoader;
  final ProposalDismissals dismissals;

  @override
  State<ShabbatDisplayProposalHost> createState() =>
      _ShabbatDisplayProposalHostState();
}

class _ShabbatDisplayProposalHostState
    extends State<ShabbatDisplayProposalHost> {
  static const _recheck = Duration(minutes: 1);

  final RestDisplayResolver _resolver = RestDisplayResolver();
  Timer? _timer;
  ShabbatPlace? _place;
  Future<ShabbatPlace>? _placeRequest;
  DateTime? _answeredEntry;
  DateTime? _proposedEntry;
  bool _tent = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAnswer());
    _timer = Timer.periodic(_recheck, (_) => _evaluate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _now() => (widget.clock ?? DateTime.now)();

  Future<void> _loadAnswer() async {
    _answeredEntry = await widget.dismissals.lastAnswered();
    _evaluate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fold = FoldScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final tent = isTentPose(fold: fold, size: size);
    if (tent == _tent) return;
    _tent = tent;
    _evaluate();
  }

  /// Decides, asynchronously, whether the card shows. Anything that is not a
  /// tent hides it at once, without a single calculation.
  void _evaluate() {
    if (!mounted) return;
    final generation = ++_generation;
    if (!_tent) {
      _setProposed(null);
      return;
    }
    unawaited(_decide(generation));
  }

  Future<void> _decide(int generation) async {
    final now = _now();
    // Paris first: far from Friday, the member's place is not worth a request.
    var content = _resolver.resolve(now: now);
    final reach = kShabbatDisplayProposalWindow + const Duration(hours: 12);
    if (content.rest.entry.difference(now) > reach) {
      return _finish(generation, null);
    }
    final place = _place ?? await _readPlace();
    if (generation != _generation || !mounted) return;
    content = _resolver.resolve(now: now, location: place.location);
    final fold = FoldScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final propose = shouldProposeShabbatDisplay(
      content: content,
      now: now,
      fold: fold,
      size: size,
    );
    final entry = content.rest.entry;
    final answered =
        _answeredEntry != null && _answeredEntry!.isAtSameMomentAs(entry);
    _finish(generation, propose && !answered ? entry : null);
  }

  Future<ShabbatPlace> _readPlace() {
    final request =
        _placeRequest ??
        (widget.placeLoader?.call() ?? loadShabbatPlace(ApiService()));
    _placeRequest = request;
    return request.then((place) => _place = place);
  }

  void _finish(int generation, DateTime? entry) {
    if (generation != _generation || !mounted) return;
    _setProposed(entry);
  }

  void _setProposed(DateTime? entry) {
    if (entry == _proposedEntry) return;
    setState(() => _proposedEntry = entry);
  }

  Future<void> _answer({required bool launch}) async {
    final entry = _proposedEntry;
    if (entry == null) return;
    _answeredEntry = entry;
    _setProposed(null);
    await widget.dismissals.answer(entry);
    if (launch) widget.onLaunch();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_proposedEntry != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.all(12),
              child: Center(
                heightFactor: 1,
                child: _ProposalCard(
                  onLaunch: () => unawaited(_answer(launch: true)),
                  onDismiss: () => unawaited(_answer(launch: false)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.onLaunch, required this.onDismiss});

  final VoidCallback onLaunch;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8, top: 4),
                child: Text(
                  l10n.shabbatDisplayProposalTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  children: [
                    TextButton(
                      onPressed: onDismiss,
                      child: Text(l10n.shabbatDisplayProposalDismiss),
                    ),
                    TextButton(
                      onPressed: onLaunch,
                      child: Text(l10n.shabbatDisplayLaunch),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
