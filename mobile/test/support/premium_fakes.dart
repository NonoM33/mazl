import 'dart:async';

import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/core/premium/premium_settings_api.dart';
import 'package:mazl/core/premium/swipe_undo_api.dart';

/// Plays the SERVER's part of `GET /api/premium/settings`,
/// `PUT /api/discover/passport` and `PUT /api/profile/incognito`: the answers
/// the contract gives, a 402 `mazl_plus_required` for a free member who turns
/// a mazl+ feature on, and the right to turn it off.
class FakePremiumSettingsApi implements PremiumSettingsApi {
  FakePremiumSettingsApi({
    bool isPlus = true,
    Passport? passport,
    bool incognito = false,
    bool sendReadReceipts = true,
  }) : settings = PremiumSettings(
         isPlus: isPlus,
         passport: passport,
         incognito: incognito,
         sendReadReceipts: sendReadReceipts,
       );

  PremiumSettings settings;

  /// How many times the screen read the settings.
  int reads = 0;

  /// Every `setPassport` the screen sent (null: turned off).
  final List<Passport?> passportCalls = [];

  /// Every `setIncognito` the screen sent.
  final List<bool> incognitoCalls = [];

  /// When set, the next reads fail with it (the list is consumed).
  final List<PremiumSettingsException> readFailures = [];

  /// When set, every write fails with it, whatever the member's plan.
  PremiumSettingsException? writeFailure;

  /// While set, a write waits for it before the server answers.
  Completer<void>? holdWrites;

  @override
  Future<PremiumSettings> getSettings() async {
    reads++;
    if (readFailures.isNotEmpty) throw readFailures.removeAt(0);
    return settings;
  }

  @override
  Future<Passport?> setPassport(Passport? passport) async {
    passportCalls.add(passport);
    await holdWrites?.future;
    final failure = writeFailure;
    if (failure != null) throw failure;
    if (passport != null && !settings.isPlus) {
      throw const PremiumSettingsException(
        PremiumSettingsErrorKind.plusRequired,
        status: 402,
      );
    }
    settings = passport == null
        ? settings.copyWith(clearPassport: true)
        : settings.copyWith(passport: passport);
    return settings.passport;
  }

  @override
  Future<bool> setIncognito(bool enabled) async {
    incognitoCalls.add(enabled);
    await holdWrites?.future;
    final failure = writeFailure;
    if (failure != null) throw failure;
    if (enabled && !settings.isPlus) {
      throw const PremiumSettingsException(
        PremiumSettingsErrorKind.plusRequired,
        status: 402,
      );
    }
    settings = settings.copyWith(incognito: enabled);
    return enabled;
  }
}

/// Plays the SERVER's part of `POST /api/swipes/undo`.
class FakeSwipeUndoApi implements SwipeUndoApi {
  FakeSwipeUndoApi({this.answer});

  /// What the server takes back; null means it answers [failure].
  UndoneSwipe? answer;

  /// The refusal to throw when [answer] is null.
  SwipeUndoException? failure;

  /// How many times the screen asked.
  int calls = 0;

  /// While set, the call waits for it before the server answers.
  Completer<void>? hold;

  @override
  Future<UndoneSwipe> undoLastSwipe() async {
    calls++;
    await hold?.future;
    final done = answer;
    if (done != null) return done;
    throw failure ?? const SwipeUndoException(SwipeUndoErrorKind.unknown);
  }
}
