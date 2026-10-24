import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Reads the fields the member still has to give, `null` when it cannot be
/// known (offline, server too old to say).
typedef MissingFieldsFetcher = Future<List<String>?> Function();

/// Whether the signed-in member has said who they are and who they seek.
///
/// The backend refuses to build a Discover feed without it, so the router
/// sends an incomplete member to the profile setup from every protected
/// screen. This is the single place that remembers the answer: it is fetched
/// after a sign-in and after a session restore, corrected by a 409
/// `profile_incomplete` from a feed, and cleared on sign-out.
///
/// It is a [ChangeNotifier] so the router's `refreshListenable` re-runs the
/// redirect whenever the answer changes.
class ProfileCompletenessService extends ChangeNotifier {
  static final ProfileCompletenessService _shared =
      ProfileCompletenessService.create(_fetchFromApi);
  factory ProfileCompletenessService() => _shared;

  /// An independent instance with its own fetcher (tests).
  ProfileCompletenessService.create(this._fetch);

  final MissingFieldsFetcher _fetch;

  /// `null` until known; empty when complete.
  List<String>? _missing;

  static Future<List<String>?> _fetchFromApi() async {
    final response = await ApiService().getMissingProfileFields();
    return response.success ? response.data : null;
  }

  /// Fields still to give; `null` while unknown.
  List<String>? get missing => _missing == null ? null : List.unmodifiable(_missing!);

  bool get isKnown => _missing != null;

  /// True only when the backend said something is missing. While unknown the
  /// member is let through: the Discover 409 corrects it a moment later.
  bool get needsSetup => _missing != null && _missing!.isNotEmpty;

  /// Asks the backend. A failed read keeps the previous answer.
  Future<void> refresh() async {
    final List<String>? fetched;
    try {
      fetched = await _fetch();
    } catch (e) {
      debugPrint('ProfileCompletenessService: refresh failed - $e');
      return;
    }
    if (fetched != null) _set(fetched);
  }

  /// A feed answered 409 profile_incomplete.
  void markIncomplete(List<String> missing) =>
      _set(missing.isEmpty ? const ['profile'] : missing);

  /// The profile setup was saved with every required field.
  void markComplete() => _set(const []);

  /// Signed out: the next account starts unknown.
  void reset() {
    if (_missing == null) return;
    _missing = null;
    notifyListeners();
  }

  void _set(List<String> missing) {
    final changed = _missing == null || !listEquals(_missing, missing);
    _missing = List.of(missing);
    if (changed) notifyListeners();
  }
}
