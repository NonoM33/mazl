import 'package:flutter/material.dart';

import '../../../../core/verification/mrz/mrz_data.dart';
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
  Widget build(BuildContext context) => IdentityPage(
    eyebrow: 'Étape 1 / 3',
    title: 'Vérifiez ces informations.',
    onClose: onClose,
    actions: [
      IdentityPrimaryButton('C\'est bien moi', onPressed: onConfirm),
      IdentityLinkButton('Scanner à nouveau', onPressed: onReject),
    ],
    child: Column(
      children: [
        FactRow(label: 'Numéro du document', value: maskDocumentNumber(mrz.documentNumber)),
        FactRow(label: 'Date de naissance', value: formatReviewDate(mrz.birthDate())),
        FactRow(label: 'Date d\'expiration', value: formatReviewDate(mrz.expiryDate()), last: true),
      ],
    ),
  );
}
