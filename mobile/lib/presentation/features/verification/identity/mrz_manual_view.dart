import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/verification/mrz/mrz_data.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/manual_mrz_error_text.dart';
import 'identity_layout.dart';
import 'identity_parts.dart';
import 'manual_mrz_input.dart';

/// Typing the three values the chip key is made of, when the camera cannot.
class MrzManualView extends StatefulWidget {
  const MrzManualView({super.key, required this.onSubmit, required this.onUseCamera, required this.onClose});

  final ValueChanged<MrzData> onSubmit;
  final VoidCallback onUseCamera;
  final VoidCallback onClose;

  @override
  State<MrzManualView> createState() => _MrzManualViewState();
}

class _MrzManualViewState extends State<MrzManualView> {
  final _number = TextEditingController();
  final _birth = TextEditingController();
  final _expiry = TextEditingController();
  ManualMrzErrors _errors = const ManualMrzErrors();

  @override
  void dispose() {
    _number.dispose();
    _birth.dispose();
    _expiry.dispose();
    super.dispose();
  }

  void _submit() {
    final result = validateManualMrz(
      ManualMrzInput(documentNumber: _number.text, birthDate: _birth.text, expiryDate: _expiry.text),
    );
    setState(() => _errors = result.errors);
    final data = result.data;
    if (data != null) widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IdentityPage(
      eyebrow: l10n.verificationStepLabel(1, 3),
      title: l10n.verificationManualTitle,
      subtitle: l10n.verificationManualSubtitle,
      onClose: widget.onClose,
      actions: [
        IdentityPrimaryButton(l10n.commonContinue, onPressed: _submit),
        IdentityLinkButton(l10n.verificationManualUseCamera, onPressed: widget.onUseCamera),
      ],
      child: Column(
        children: [
          TextField(
            controller: _number,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            textAlign: _valueAlign(context),
            decoration: InputDecoration(
              labelText: l10n.verificationFieldDocumentNumber,
              errorText: _errors.documentNumber?.text(l10n),
            ),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]'))],
          ),
          const SizedBox(height: 16),
          _dateField(context, _birth, l10n.verificationFieldBirthDate, _errors.birthDate),
          const SizedBox(height: 16),
          _dateField(context, _expiry, l10n.verificationFieldExpiryDate, _errors.expiryDate),
        ],
      ),
    );
  }

  /// Letters and digits are typed left to right in every language, but the
  /// value still sits on the side the rest of the form starts from.
  TextAlign _valueAlign(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? TextAlign.end : TextAlign.start;

  Widget _dateField(BuildContext context, TextEditingController controller, String label, ManualMrzError? error) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        textAlign: _valueAlign(context),
        inputFormatters: const [FrenchDateInputFormatter()],
        decoration: InputDecoration(
          labelText: label,
          hintText: context.l10n.verificationDateHint,
          hintTextDirection: TextDirection.ltr,
          errorText: error?.text(context.l10n),
        ),
      );
}
