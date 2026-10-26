import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/fold_spread.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../l10n/l10n.dart';
import '../shabbat_place.dart';
import '../widgets/shabbat_hero.dart';

/// Mode Shabbat : les horaires d'allumage et de havdala du lieu du membre, sur
/// l'écran de repos. L'app ne met rien en pause : l'écran ne le promet pas.
///
/// Le lieu est celui du profil (coordonnées de la ville). Sans coordonnées, ou
/// si le profil ne peut pas être lu, ce sont les horaires de Paris, et l'écran
/// le dit.
class ShabbatModeScreen extends StatefulWidget {
  const ShabbatModeScreen({super.key, this.apiService, this.clock});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  /// L'heure qu'il est ; injectée par les tests.
  final DateTime Function()? clock;

  @override
  State<ShabbatModeScreen> createState() => _ShabbatModeScreenState();
}

class _ShabbatModeScreenState extends State<ShabbatModeScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();

  ShabbatInfo? _shabbat;

  /// Le nom du lieu du membre ; null quand les horaires sont ceux de Paris
  /// par défaut.
  String? _place;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final place = await loadShabbatPlace(_api);
    final shabbat = JewishCalendarService().getThisWeekShabbat(
      location: place.location,
      now: widget.clock?.call(),
    );
    if (!mounted) return;
    setState(() {
      _shabbat = shabbat;
      _place = place.isDefault ? null : place.location.name;
    });
  }

  /// Le service rend « --:-- » quand le calcul astronomique échoue.
  static String _display(String? time) =>
      time == null || time.contains('-') ? '—' : time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final shabbat = _shabbat;
    final place = _place;
    final usesDefaultPlace = shabbat != null && place == null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // Held like a book: the dark hero (times, place) on the page where the
        // reading starts, the launch button and the explanation on the other.
        body: FoldSpread(
          start: [
            ShabbatHero(
              candleLighting: _display(shabbat?.candleLighting),
              havdala: _display(shabbat?.havdala),
              city: shabbat == null
                  ? ''
                  : l10n.settingsShabbatBasedOn(
                      place ?? l10n.settingsShabbatDefaultPlace,
                    ),
              onBack: () => context.pop(),
            ),
          ],
          end: [
            if (shabbat != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Text(
                  usesDefaultPlace
                      ? l10n.settingsShabbatUnknownPlaceHint
                      : l10n.settingsShabbatExplanation,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
