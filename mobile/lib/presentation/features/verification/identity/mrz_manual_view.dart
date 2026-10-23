import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/verification/mrz/mrz_data.dart';
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
  Widget build(BuildContext context) => IdentityPage(
    eyebrow: 'Étape 1 / 3',
    title: 'Saisissez les informations.',
    subtitle: 'Recopiez-les depuis la page photo de votre document.',
    onClose: widget.onClose,
    actions: [
      IdentityPrimaryButton('Continuer', onPressed: _submit),
      IdentityLinkButton('Scanner avec la caméra', onPressed: widget.onUseCamera),
    ],
    child: Column(
      children: [
        TextField(
          controller: _number,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: 'Numéro du document', errorText: _errors.documentNumber),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]'))],
        ),
        const SizedBox(height: 16),
        _dateField(_birth, 'Date de naissance', _errors.birthDate),
        const SizedBox(height: 16),
        _dateField(_expiry, 'Date d\'expiration', _errors.expiryDate),
      ],
    ),
  );

  Widget _dateField(TextEditingController controller, String label, String? error) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: const [FrenchDateInputFormatter()],
    decoration: InputDecoration(labelText: label, hintText: 'JJ/MM/AAAA', errorText: error),
  );
}
