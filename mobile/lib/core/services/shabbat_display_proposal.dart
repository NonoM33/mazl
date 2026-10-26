import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../layout/fold_state.dart';
import 'rest_display_content.dart';

/// How long before candle lighting the display is proposed.
const Duration kShabbatDisplayProposalWindow = Duration(hours: 4);

/// Whether the app should propose the Shabbat display now: the phone is a
/// foldable iPhone standing like a tent (closed, held sideways), and the next
/// rest begins within [window] (the afternoon of Friday, or of the eve of a
/// festival). Never while the rest is on, never on another phone, never when
/// the sun does not set (no hour to count from).
bool shouldProposeShabbatDisplay({
  required RestDisplayContent content,
  required DateTime now,
  required FoldState fold,
  required Size size,
  Duration window = kShabbatDisplayProposalWindow,
}) {
  final tent =
      fold.isFoldable &&
      fold.hinge == HingeStatus.closed &&
      size.width > size.height;
  if (!tent || content.moment == RestDisplayMoment.resting) return false;
  if (!content.rest.timesKnown) return false;
  final untilEntry = content.rest.entry.difference(now);
  return untilEntry > Duration.zero && untilEntry <= window;
}

/// Remembers the rest whose proposal the member has answered, so that it comes
/// back neither at every launch nor after the display is closed.
abstract interface class ProposalDismissals {
  /// The entry of the last rest the proposal was answered for, if any.
  Future<DateTime?> lastAnswered();

  Future<void> answer(DateTime entry);
}

class PreferencesProposalDismissals implements ProposalDismissals {
  const PreferencesProposalDismissals();

  static const _key = 'shabbat_display_proposal_answered_entry';

  @override
  Future<DateTime?> lastAnswered() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_key);
    return stored == null ? null : DateTime.tryParse(stored);
  }

  @override
  Future<void> answer(DateTime entry) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, entry.toUtc().toIso8601String());
  }
}
