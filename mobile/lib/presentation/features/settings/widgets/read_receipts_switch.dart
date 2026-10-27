import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/premium/read_receipts_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// « Envoyer les confirmations de lecture » (docs/premium/MONETISATION.md §4).
///
/// The server holds the value: the switch shows what it answered, asks for a
/// change and keeps what it answers back. When the change fails, the switch
/// goes back to the server's state (read again), never stays where the finger
/// put it.
class ReadReceiptsSwitch extends StatefulWidget {
  const ReadReceiptsSwitch({super.key, this.api});

  /// Injected by tests; the app uses the real client.
  final ReadReceiptsApi? api;

  @override
  State<ReadReceiptsSwitch> createState() => _ReadReceiptsSwitchState();
}

class _ReadReceiptsSwitchState extends State<ReadReceiptsSwitch> {
  late final ReadReceiptsApi _api = widget.api ?? HttpReadReceiptsApi();

  /// Null until the server has answered.
  bool? _value;
  bool _loadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final held = await _api.load();
      if (!mounted) return;
      setState(() => _value = held);
    } on ReadReceiptsException {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _toggle(bool wanted) async {
    final previous = _value;
    if (_saving || previous == null) return;
    setState(() {
      _saving = true;
      _value = wanted;
    });
    try {
      final held = await _api.set(wanted);
      if (!mounted) return;
      setState(() {
        _value = held;
        _saving = false;
      });
    } on ReadReceiptsException {
      final held = await _readAgain();
      if (!mounted) return;
      setState(() {
        _value = held ?? previous;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.readReceiptsSaveFailed)),
      );
    }
  }

  /// The server's state after a failed change, null when it cannot be read.
  Future<bool?> _readAgain() async {
    try {
      return await _api.load();
    } on ReadReceiptsException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = _value;
    final canToggle = value != null && !_saving;
    return ListTile(
      leading: const Icon(LucideIcons.checkCheck, color: AppColors.primary),
      title: Text(l10n.readReceiptsTitle),
      subtitle: Text(
        _loadFailed ? l10n.readReceiptsLoadFailed : l10n.readReceiptsSubtitle,
      ),
      trailing: value == null && !_loadFailed
          // The server has not answered yet.
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: value ?? false,
              onChanged: canToggle ? _toggle : null,
            ),
      onTap: _loadFailed
          ? _load
          : canToggle
          ? () => _toggle(!value)
          : null,
    );
  }
}
