import 'package:flutter/material.dart';

import '../../../../core/verification/mrz/mrz_data.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'identity_layout.dart';
import 'identity_parts.dart';
import 'mrz_review_format.dart';

/// What was read from the photo page, before the chip is opened with it.
class MrzReviewView extends StatelessWidget {
  const MrzReviewView({
    super.key,
    required this.mrz,
    required this.onConfirm,
    required this.onReject,
    required this.onClose,
  });

  final MrzData mrz;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    return IdentityPage(
      eyebrow: l10n.verificationStepLabel(1, 3),
      title: l10n.verificationReviewTitle,
      onClose: onClose,
      actions: [
        IdentityPrimaryButton(l10n.verificationReviewConfirm, onPressed: onConfirm),
        IdentityLinkButton(l10n.verificationRescan, onPressed: onReject),
      ],
      child: Column(
        children: [
          FactRow(label: l10n.verificationFieldDocumentNumber, value: reviewDocumentNumber(mrz.documentNumber)),
          FactRow(label: l10n.verificationFieldBirthDate, value: formatReviewDate(mrz.birthDate(), locale)),
          FactRow(
            label: l10n.verificationFieldExpiryDate,
            value: formatReviewDate(mrz.expiryDate(), locale),
            last: true,
          ),
        ],
      ),
    );
  }
}
