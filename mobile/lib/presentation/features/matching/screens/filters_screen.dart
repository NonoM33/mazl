import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/matching/discover_filters.dart';
import '../../../../core/matching/discover_filters_api.dart';
import '../../../../core/matching/discover_filters_providers.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../privacy/widgets/religious_consent_sheet.dart';
import '../l10n/filter_options.dart';

/// Discovery filters. Age and distance describe the search and stay in the
/// profile (free); the advanced filters (religious practice, verified, photo)
/// are mazl+ and live on the server apart from the profile
/// (`GET/PUT /api/discover/filters`).
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

enum _AdvancedState { loading, ready, failed }

/// What the member ticked: choices, not spellings. A choice stands for every
/// spelling the profiles hold ([FilterChoice.storedValues]), so comparing the
/// choices tells whether the member changed anything, whereas comparing the
/// answers sent would not (the server keeps only the spellings that were sent).
class _Selection {
  _Selection({
    required this.denominations,
    required this.kashrut,
    required this.shabbat,
    required this.onlyVerified,
    required this.onlyWithPhoto,
  });

  factory _Selection.empty() => _Selection(
    denominations: {},
    kashrut: {},
    shabbat: {},
    onlyVerified: false,
    onlyWithPhoto: false,
  );

  factory _Selection.of(DiscoverFilters filters) {
    Set<FilterChoice> chosen(List<FilterChoice> all, List<String>? saved) =>
        saved == null ? {} : {...all.where((c) => c.isIn(saved))};
    return _Selection(
      denominations: chosen(denominationChoices, filters.denominations),
      kashrut: chosen(kashrutChoices, filters.kashrutLevels),
      shabbat: chosen(shabbatChoices, filters.shabbatObservances),
      onlyVerified: filters.onlyVerified,
      onlyWithPhoto: filters.onlyWithPhoto,
    );
  }

  final Set<FilterChoice> denominations;
  final Set<FilterChoice> kashrut;
  final Set<FilterChoice> shabbat;
  bool onlyVerified;
  bool onlyWithPhoto;

  _Selection copy() => _Selection(
    denominations: {...denominations},
    kashrut: {...kashrut},
    shabbat: {...shabbat},
    onlyVerified: onlyVerified,
    onlyWithPhoto: onlyWithPhoto,
  );

  /// The body of the save: every criterion, `null` for none.
  DiscoverFilters toFilters() {
    List<String>? answers(Set<FilterChoice> selected) =>
        selected.isEmpty ? null : answersOf(selected);
    return DiscoverFilters(
      denominations: answers(denominations),
      kashrutLevels: answers(kashrut),
      shabbatObservances: answers(shabbat),
      onlyVerified: onlyVerified,
      onlyWithPhoto: onlyWithPhoto,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _Selection &&
      _sameSet(denominations, other.denominations) &&
      _sameSet(kashrut, other.kashrut) &&
      _sameSet(shabbat, other.shabbat) &&
      onlyVerified == other.onlyVerified &&
      onlyWithPhoto == other.onlyWithPhoto;

  @override
  int get hashCode => Object.hash(
    denominations.length,
    kashrut.length,
    shabbat.length,
    onlyVerified,
    onlyWithPhoto,
  );

  static bool _sameSet(Set<FilterChoice> a, Set<FilterChoice> b) =>
      a.length == b.length && a.containsAll(b);
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  static const _defaultAges = RangeValues(18, 45);
  static const _defaultDistance = 50.0;

  late final ApiService _apiService = widget.apiService ?? ApiService();
  late final DiscoverFiltersApi _filtersApi = ref.read(
    discoverFiltersApiProvider,
  );

  bool _isSaving = false;

  // Age and distance, and what the profile holds.
  RangeValues _ageRange = _defaultAges;
  double _distanceMax = _defaultDistance;
  RangeValues _savedAgeRange = _defaultAges;
  double _savedDistanceMax = _defaultDistance;

  // The advanced filters, and what the server holds.
  _AdvancedState _advanced = _AdvancedState.loading;
  bool _plus = false;
  _Selection _savedSelection = _Selection.empty();
  _Selection _selection = _Selection.empty();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFilters();
  }

  Future<void> _loadProfile() async {
    final response = await _apiService.getCurrentUser();
    if (!mounted || !response.success || response.data?.profile == null) {
      return;
    }
    final profile = response.data!.profile!;
    setState(() {
      _savedAgeRange = RangeValues(
        (profile.ageMin ?? 18).toDouble(),
        (profile.ageMax ?? 45).toDouble(),
      );
      _savedDistanceMax = (profile.distanceMax ?? 50).toDouble();
      _ageRange = _savedAgeRange;
      _distanceMax = _savedDistanceMax;
    });
  }

  Future<void> _loadFilters() async {
    setState(() => _advanced = _AdvancedState.loading);
    final response = await _filtersApi.load();
    if (!mounted) return;
    final state = response.data;
    if (!response.success || state == null) {
      setState(() => _advanced = _AdvancedState.failed);
      return;
    }
    setState(() {
      _plus = state.plus;
      _savedSelection = _Selection.of(state.filters);
      _selection = _savedSelection.copy();
      _advanced = _AdvancedState.ready;
    });
  }

  bool get _profileChanged =>
      _ageRange != _savedAgeRange || _distanceMax != _savedDistanceMax;

  // Only once the server's filters are known: before that nothing is changed.
  bool get _filtersChanged =>
      _advanced == _AdvancedState.ready && _selection != _savedSelection;

  bool get _hasChanges => _profileChanged || _filtersChanged;

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    var saved = true;
    if (_profileChanged) saved = await _saveProfile();
    if (saved && _filtersChanged) saved = await _saveFilters();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      _snack(context.l10n.matchingFiltersSaved, AppColors.success);
      Navigator.pop(context, true);
    }
  }

  Future<bool> _saveProfile() async {
    final response = await _apiService.updateProfile({
      'ageMin': _ageRange.start.round(),
      'ageMax': _ageRange.end.round(),
      'distanceMax': _distanceMax.round(),
    });
    if (!mounted) return false;
    if (!response.success) {
      _snack(context.l10n.matchingFiltersSaveFailed, AppColors.error);
      return false;
    }
    _savedAgeRange = _ageRange;
    _savedDistanceMax = _distanceMax;
    return true;
  }

  Future<bool> _saveFilters({bool afterConsent = false}) async {
    final response = await _filtersApi.save(_selection.toFilters());
    if (!mounted) return false;
    if (response.success) {
      _savedSelection = _selection.copy();
      return true;
    }
    switch (response.errorCode) {
      case DiscoverFiltersError.plusRequired:
        await _openPremium();
      case DiscoverFiltersError.religiousConsentRequired:
        if (!afterConsent && await _askReligiousConsent()) {
          return _saveFilters(afterConsent: true);
        }
        if (mounted) {
          _snack(context.l10n.matchingFiltersConsentNeeded, AppColors.error);
        }
      default:
        _snack(context.l10n.matchingFiltersSaveFailed, AppColors.error);
    }
    return false;
  }

  /// The religious criteria need the article 9 consent: the member is asked in
  /// the usual sheet. True when it was given.
  Future<bool> _askReligiousConsent() async {
    final consent =
        (await ref.read(privacyConsentApiProvider).religiousData()).data;
    if (!mounted || consent == null) return false;
    final granted = await showReligiousConsentSheet(context, consent);
    ref.invalidate(religiousDataConsentProvider);
    return granted == true;
  }

  /// The subscription screen, then the server is asked again who is mazl+.
  Future<void> _openPremium() async {
    await context.push<bool>(RoutePaths.premium);
    if (mounted) await _loadFilters();
  }

  void _resetFilters() {
    setState(() {
      _ageRange = _defaultAges;
      _distanceMax = _defaultDistance;
      _selection = _Selection.empty();
    });
  }

  void _toggle(Set<FilterChoice> into, FilterChoice choice, bool selected) {
    setState(() => selected ? into.add(choice) : into.remove(choice));
  }

  @override
  Widget build(BuildContext context) {
    final locked = !_plus;
    final advanced = _advancedSections(locked);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.matchingFilters),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(context.l10n.matchingFiltersReset),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Held like a book: the search on the first page, the religious
          // criteria and the options on the other.
          FoldSpread(
            padding: const EdgeInsets.all(16),
            start: [
              _FilterSection(
                title: context.l10n.matchingFiltersAge,
                icon: LucideIcons.users,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.matchingFiltersYears(
                            _ageRange.start.round(),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          context.l10n.matchingFiltersYears(
                            _ageRange.end.round(),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 70,
                      divisions: 52,
                      activeColor: AppColors.primary,
                      onChanged: (values) => setState(() => _ageRange = values),
                    ),
                  ],
                ),
              ),
              _FilterSection(
                title: context.l10n.matchingFiltersDistance,
                icon: LucideIcons.mapPin,
                child: Column(
                  children: [
                    Text(
                      context.l10n.matchingFiltersKm(_distanceMax.round()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Slider(
                      value: _distanceMax,
                      min: 5,
                      max: 200,
                      divisions: 39,
                      activeColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => _distanceMax = value),
                    ),
                  ],
                ),
              ),
              ...advanced.start,
            ],
            end: [
              ...advanced.end,
              const SizedBox(height: 100), // Space for the apply button
            ],
          ),
          if (_hasChanges)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SafeArea(
                child: FoldSafeActions(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            context.l10n.matchingFiltersApply,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The advanced criteria, split for the two pages of the book: the
  /// denomination follows the search on the first page, the rest is on the
  /// other. Flat the two are one list, in the same order as ever.
  ({List<Widget> start, List<Widget> end}) _advancedSections(bool locked) {
    switch (_advanced) {
      case _AdvancedState.loading:
        return (
          start: const [],
          end: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      case _AdvancedState.failed:
        return (
          start: const [],
          end: [
            _FilterSection(
              title: context.l10n.matchingFiltersAdvanced,
              icon: LucideIcons.settings,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.matchingFiltersLoadFailed),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadFilters,
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ],
        );
      case _AdvancedState.ready:
        return (
          start: [
            _choiceSection(
              title: context.l10n.matchingFiltersDenomination,
              icon: LucideIcons.star,
              choices: denominationChoices,
              selected: _selection.denominations,
              locked: locked,
            ),
          ],
          end: [
            _choiceSection(
              title: context.l10n.matchingFiltersKashrut,
              icon: LucideIcons.utensils,
              choices: kashrutChoices,
              selected: _selection.kashrut,
              locked: locked,
            ),
            _choiceSection(
              title: context.l10n.matchingFiltersShabbatSection,
              icon: LucideIcons.heart,
              choices: shabbatChoices,
              selected: _selection.shabbat,
              locked: locked,
            ),
            _FilterSection(
              title: context.l10n.matchingFiltersOptions,
              icon: LucideIcons.settings,
              locked: locked,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.l10n.matchingFiltersVerifiedTitle),
                    subtitle: Text(context.l10n.matchingFiltersVerifiedHint),
                    value: _selection.onlyVerified,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _selection.onlyVerified = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: Text(context.l10n.matchingFiltersPhotoTitle),
                    subtitle: Text(context.l10n.matchingFiltersPhotoHint),
                    value: _selection.onlyWithPhoto,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _selection.onlyWithPhoto = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (locked) _upsell(),
          ],
        );
    }
  }

  Widget _choiceSection({
    required String title,
    required IconData icon,
    required List<FilterChoice> choices,
    required Set<FilterChoice> selected,
    required bool locked,
  }) {
    return _FilterSection(
      title: title,
      icon: icon,
      locked: locked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in choices)
                FilterChip(
                  label: Text(choice.label(context.l10n)),
                  selected: selected.contains(choice),
                  onSelected: (on) => _toggle(selected, choice, on),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.matchingFiltersChoiceHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _upsell() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.premiumGradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.plus, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.matchingFiltersUpsellTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.l10n.matchingFiltersUpsellBody,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openPremium,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: Text(context.l10n.commonSee),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
    this.locked = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.lock,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'mazl+',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: locked ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: locked,
              // The list tiles paint their ink here, above the card's colour.
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
