import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/column_app_bar.dart';
import '../../../../core/layout/fold_aware_split.dart';
import '../../../../core/layout/fold_message_view.dart';
import '../../../../core/premium/passport_cities.dart';
import '../../../../core/premium/premium_settings.dart';
import '../../../../core/premium/premium_settings_api.dart';
import '../../../../core/premium/purchase_moments.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/places_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/passport_city_label.dart';
import '../l10n/premium_error_text.dart';
import '../widgets/passport_city_row.dart';

/// What the Passeport screen hands back to Discover when the passport changed:
/// the passport the server now holds, null when it was turned off.
class PassportChange {
  const PassportChange(this.passport);

  final Passport? passport;
}

/// Looks cities up from what the member typed.
typedef CitySearch = Future<List<CitySuggestion>> Function(String query);

/// Shows the offer for a moment (the mazl+ page, at most once a day).
typedef PlusOffer =
    Future<bool> Function(BuildContext context, PurchaseMoment moment);

/// The Passeport (mazl+): choose another city for Discover, with the city on
/// the member's own profile left as it is. The member's current passport comes
/// from the server; a member without mazl+ sees the cities and, on a tap, the
/// mazl+ offer (the server refuses the change with 402 in any case).
class PassportScreen extends StatefulWidget {
  const PassportScreen({
    super.key,
    this.api,
    this.searchCities,
    this.offerPlus,
  });

  /// Injected by tests; the app uses the real client.
  final PremiumSettingsApi? api;

  /// Injected by tests; the app uses the Geoplateforme geocoder of
  /// [PlacesService].
  final CitySearch? searchCities;

  /// Injected by tests; the app uses [PurchaseMoments.offer].
  final PlusOffer? offerPlus;

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  static const _searchDelay = Duration(milliseconds: 350);
  static const _pagePadding = EdgeInsets.fromLTRB(24, 8, 24, 48);

  late final PremiumSettingsApi _api = widget.api ?? HttpPremiumSettingsApi();
  late final CitySearch _search =
      widget.searchCities ?? PlacesService().searchCities;
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;

  PremiumSettings? _settings;
  bool _loading = true;
  bool _busy = false;

  List<CitySuggestion> _results = const [];
  bool _searched = false;

  /// Bumped with each search so a slow, older answer never replaces a newer one.
  int _searchRound = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    PremiumSettings? settings;
    try {
      settings = await _api.getSettings();
    } on PremiumSettingsException catch (error) {
      debugPrint('Passport settings unavailable: ${error.kind.name}');
    }
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      _searchRound++;
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(_searchDelay, () => unawaited(_runSearch(text)));
  }

  Future<void> _runSearch(String text) async {
    final round = ++_searchRound;
    final found = await _search(text);
    if (!mounted || round != _searchRound) return;
    setState(() {
      _results = [
        for (final city in found)
          if (city.latitude != null &&
              city.longitude != null &&
              city.city.trim().isNotEmpty)
            city,
      ];
      _searched = true;
    });
  }

  Future<bool> _offer() => (widget.offerPlus ?? PurchaseMoments.offer)(
    context,
    PurchaseMoment.passportAttempt,
  );

  /// Turns the passport on for [passport], or off with null.
  Future<void> _choose(Passport? passport) async {
    final settings = _settings;
    if (_busy || settings == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // Turning it off is always allowed; turning it on needs mazl+.
    if (passport != null && !settings.isPlus) {
      await _offer();
      return;
    }
    setState(() => _busy = true);
    try {
      final held = await _api.setPassport(passport);
      if (!mounted) return;
      Navigator.pop(context, PassportChange(held));
    } on PremiumSettingsException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (error.kind == PremiumSettingsErrorKind.plusRequired) {
        await _offer();
      } else {
        _say(
          error.kind == PremiumSettingsErrorKind.unknown
              ? context.l10n.passportSaveFailed
              : premiumErrorText(context.l10n, error.kind),
        );
      }
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ColumnAppBar(
      appBar: AppBar(title: Text(context.l10n.passportTitle)),
    ),
    body: _body(context),
  );

  Widget _body(BuildContext context) {
    if (_loading) return const FoldSpinner();
    final settings = _settings;
    if (settings == null) {
      return FoldMessageView(
        icon: LucideIcons.circleAlert,
        title: context.l10n.passportLoadFailed,
        actionLabel: context.l10n.commonRetry,
        onAction: _load,
      );
    }
    return FoldAwareSplit(
      lead: SingleChildScrollView(
        padding: _pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _header(context, settings),
        ),
      ),
      action: Builder(
        builder: (context) {
          final split = FoldAwareSplit.axisOf(context) != null;
          return ListView(
            padding: _pagePadding,
            children: [
              if (!split) ..._header(context, settings),
              ..._actions(context, settings),
            ],
          );
        },
      ),
    );
  }

  /// What the page says: the title, the explanation and where the member is.
  List<Widget> _header(BuildContext context, PremiumSettings settings) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final passport = settings.passport;
    return [
      SectionLabel(l10n.passportTitle, color: scheme.primary),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(
          l10n.passportHeadline,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        l10n.passportIntro,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: scheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      Semantics(
        liveRegion: true,
        child: Text(
          passport == null
              ? l10n.passportInactive
              : l10n.passportCurrent(
                  passportServerCityLabel(l10n, passport.city),
                ),
          key: const ValueKey('passport-current'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  /// What the member can touch: back to their city, the search, the cities.
  List<Widget> _actions(BuildContext context, PremiumSettings settings) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final held = settings.passport;
    return [
      if (!settings.isPlus) ...[
        Text(
          l10n.passportPlusOnly,
          key: const ValueKey('passport-plus-only'),
          style: TextStyle(fontSize: 15, color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            key: const ValueKey('passport-see-plus'),
            onPressed: () => context.push(RoutePaths.premium),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(l10n.passportSeePlus),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (held != null) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('passport-back-home'),
            onPressed: _busy ? null : () => _choose(null),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(LucideIcons.house, size: 18),
            label: Text(l10n.passportBackHome),
          ),
        ),
        const SizedBox(height: 16),
      ],
      TextField(
        key: const ValueKey('passport-search'),
        controller: _query,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: l10n.passportSearchLabel,
          prefixIcon: const Icon(LucideIcons.search, size: 20),
        ),
      ),
      const SizedBox(height: 8),
      if (_searched) ..._resultRows(context, held),
      _sectionTitle(l10n.passportSuggestedTitle),
      for (final city in PassportCity.values)
        PassportCityRow(
          key: ValueKey('passport-city-${city.name}'),
          label: passportCityLabel(l10n, city),
          selected: held != null && PassportCity.named(held.city) == city,
          onTap: _busy ? null : () => _choose(city.passport),
        ),
    ];
  }

  List<Widget> _resultRows(BuildContext context, Passport? held) {
    final l10n = context.l10n;
    if (_results.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l10n.passportSearchNone,
            key: const ValueKey('passport-search-none'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      _sectionTitle(l10n.passportResultsTitle),
      for (final (index, city) in _results.indexed)
        PassportCityRow(
          key: ValueKey('passport-result-$index'),
          label: city.displayName,
          selected: held != null && held.city == city.city,
          onTap: _busy ? null : () => _choose(_passportOf(city)),
        ),
    ];
  }

  /// The server keeps at most 80 characters of a city name.
  Passport _passportOf(CitySuggestion city) {
    final name = city.city.trim();
    return Passport(
      city: name.length <= 80 ? name : name.substring(0, 80),
      latitude: city.latitude!,
      longitude: city.longitude!,
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: SectionLabel(text),
  );
}
