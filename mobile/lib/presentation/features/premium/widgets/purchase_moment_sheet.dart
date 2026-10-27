import 'package:flutter/material.dart';

import '../../../../core/premium/purchase_moments.dart';
import '../../../../l10n/l10n.dart';
import 'plus_widgets.dart';

/// The offer shown by itself at a [PurchaseMoment] (docs/premium/MONETISATION.md
/// §9). Pops with `true` to open the offer, `false` (or nothing, when the
/// sheet is dragged away) for « Plus tard ». The two buttons have the same
/// size and weight; there is no countdown and no deadline.
class PurchaseMomentSheet extends StatelessWidget {
  const PurchaseMomentSheet({super.key, required this.moment});

  final PurchaseMoment moment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final (title, body) = _texts(l10n, moment);
    return PlusSheetFrame(
      children: [
        Text(title, style: plusSheetTitleStyle(context)),
        const SizedBox(height: 12),
        Text(
          body,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        PlusCtaButton(
          label: l10n.plusDiscover,
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonLater),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.momentsPriceNote,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  static (String, String) _texts(
    AppLocalizations l10n,
    PurchaseMoment moment,
  ) => switch (moment) {
    PurchaseMoment.dailyLikeLimit => (
      l10n.plusDailyLimitTitle,
      l10n.plusDailyLimitBody,
    ),
    PurchaseMoment.thirdLikeReceived => (
      l10n.momentsThirdLikeTitle,
      l10n.momentsThirdLikeBody,
    ),
    PurchaseMoment.undoRefused => (l10n.momentsUndoTitle, l10n.momentsUndoBody),
    PurchaseMoment.passportAttempt => (
      l10n.momentsPassportTitle,
      l10n.momentsPassportBody,
    ),
    PurchaseMoment.firstMatch => (
      l10n.momentsFirstMatchTitle,
      l10n.momentsFirstMatchBody,
    ),
  };
}
