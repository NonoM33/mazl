import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/app_language_controller.dart';
import '../../../../l10n/l10n.dart';

/// The language list of the settings: « phone language », then each
/// language written in itself, so it can be found whatever the current one.
class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key, this.onChosen});

  /// Called after a choice, to close the sheet.
  final VoidCallback? onChosen;

  static const checkKey = Key('language-picker-check');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appLanguageProvider);
    Future<void> choose(AppLanguage? language) async {
      await ref.read(appLanguageProvider.notifier).choose(language);
      onChosen?.call();
    }

    Widget option(String label, AppLanguage? language) => ListTile(
      title: Text(label),
      trailing: current == language
          ? const Icon(LucideIcons.check, key: checkKey)
          : null,
      onTap: () => choose(language),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(context.l10n.settingsLanguageSystem, null),
        for (final language in AppLanguage.values)
          option(language.autonym, language),
      ],
    );
  }
}
