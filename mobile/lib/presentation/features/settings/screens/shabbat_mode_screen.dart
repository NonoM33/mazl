import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/jewish_calendar_service.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/shabbat_hero.dart';

class ShabbatModeScreen extends StatefulWidget {
  const ShabbatModeScreen({super.key});

  @override
  State<ShabbatModeScreen> createState() => _ShabbatModeScreenState();
}

class _ShabbatModeScreenState extends State<ShabbatModeScreen> {
  static const _city = 'Basé sur Paris, France';

  bool _isEnabled = true;
  bool _includeHolidays = true;
  int _bufferMinutes = 18;

  late final ShabbatInfo _shabbat = JewishCalendarService().getThisWeekShabbat();

  /// Le service rend « --:-- » quand le calcul astronomique échoue.
  static String _display(String time) => time.contains('-') ? '—' : time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            ShabbatHero(
              candleLighting: _display(_shabbat.candleLighting),
              havdala: _display(_shabbat.havdala),
              city: _city,
              onBack: () => context.pop(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: SectionLabel('Réglages'),
            ),
            const SizedBox(height: 8),
            _SwitchRow(
              title: 'Activer le mode Shabbat',
              subtitle: 'Pause automatique des notifications pendant Shabbat',
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            if (_isEnabled) ...[
              _SwitchRow(
                title: 'Inclure les fêtes',
                subtitle: 'Pause aussi pendant Yom Tov',
                value: _includeHolidays,
                onChanged: (value) => setState(() => _includeHolidays = value),
              ),
              _BufferRow(
                minutes: _bufferMinutes,
                onChanged: (value) => setState(() => _bufferMinutes = value),
              ),
              _LocationRow(
                label: _city,
                onEdit: () {
                  // TODO: Change location
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Text(
                  'Les notifications sont mises en pause et les messages attendent. '
                  'Vous recevrez tout après la fin de Shabbat, et votre statut '
                  'affichera « Mode Shabbat ».',
                  style: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          value: value,
          onChanged: onChanged,
        ),
        const _Hairline(),
      ],
    );
  }
}

class _BufferRow extends StatelessWidget {
  const _BufferRow({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Buffer avant allumage',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text('$minutes min', style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)),
                ],
              ),
              Slider(
                value: minutes.toDouble(),
                min: 0,
                max: 30,
                divisions: 6,
                label: '$minutes min',
                semanticFormatterCallback: (value) => '${value.toInt()} minutes',
                onChanged: (value) => onChanged(value.toInt()),
              ),
            ],
          ),
        ),
        const _Hairline(),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.label, required this.onEdit});

  final String label;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.mapPin, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 15, color: scheme.onSurface)),
              ),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
        const _Hairline(),
      ],
    );
  }
}
