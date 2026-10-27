import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/common/widgets/mazl_sheet.dart';
import '../../presentation/features/premium/widgets/purchase_moment_sheet.dart';
import '../analytics/analytics_event.dart';
import '../analytics/track_event.dart';
import '../router/route_names.dart';
import '../services/premium_gate.dart';
import '../theme/app_colors.dart';

/// The moments when the mazl+ offer is shown by itself, at most once a day
/// each, always with a visible « Plus tard » (docs/premium/MONETISATION.md §9).
enum PurchaseMoment {
  /// The day's likes are gone.
  dailyLikeLimit,

  /// The member just received their third like.
  thirdLikeReceived,

  /// The server refused an undo (the free one of the day is used).
  undoRefused,

  /// The member tried the passport without mazl+.
  passportAttempt,

  /// The member's first match.
  firstMatch,
}

/// Shows the offer for a [PurchaseMoment] when it has not been shown today,
/// and tells the usage measurement what happened (shown, accepted, dismissed:
/// the consent is checked by `Analytics`, not here).
///
/// The day is the local calendar day. It is kept on the phone, per moment, and
/// also in memory so that a storage that fails never turns into a second offer.
abstract final class PurchaseMoments {
  static const _keyPrefix = 'purchase_moment.last_shown.';

  static const _thirdLikeKey = 'purchase_moment.third_like_done';
  static const _firstMatchKey = 'purchase_moment.first_match_done';

  /// The once-for-good moments already done, in this session.
  static final Set<String> _done = {};

  /// Day (« 2026-10-27 ») each moment was claimed in this session.
  static final Map<PurchaseMoment, String> _claimed = {};

  /// The local clock. Replaced by tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// The local storage. Replaced by tests.
  @visibleForTesting
  static Future<SharedPreferences> Function() preferences =
      SharedPreferences.getInstance;

  /// Forgets the session (the stored days stay), as after a restart.
  @visibleForTesting
  static void forgetMemoryForTest() {
    _claimed.clear();
    _done.clear();
  }

  /// Back to the real clock and storage, nothing claimed.
  @visibleForTesting
  static void resetForTest() {
    _claimed.clear();
    _done.clear();
    clock = DateTime.now;
    preferences = SharedPreferences.getInstance;
  }

  /// Offers mazl+ for [moment]. Returns true when the offer was shown (whatever
  /// the answer), false when it was not: already shown today, the member is a
  /// subscriber, or the screen is gone.
  static Future<bool> offer(BuildContext context, PurchaseMoment moment) async {
    if (PremiumGate.isPremium) return false;
    if (!await _claimToday(moment)) return false;
    if (!context.mounted) {
      _claimed.remove(moment);
      return false;
    }
    unawaited(_remember(moment));
    final accepted = await _measured(context, moment, () async {
      final answer = await showMazlSheet<bool>(
        context,
        barrierColor: AppColors.ink.withValues(alpha: 0.45),
        isScrollControlled: true,
        builder: (_) => PurchaseMomentSheet(moment: moment),
      );
      return answer == true;
    });
    if (accepted && context.mounted) {
      unawaited(context.push<bool>(RoutePaths.premium));
    }
    return true;
  }

  /// The member received [receivedLikes] likes without mazl+: from the third
  /// on, the offer of [PurchaseMoment.thirdLikeReceived], once for good.
  static Future<bool> offerThirdLike(
    BuildContext context, {
    required int receivedLikes,
  }) async {
    if (receivedLikes < 3) return false;
    if (await _alreadyDone(_thirdLikeKey)) return false;
    if (!context.mounted) return false;
    final shown = await offer(context, PurchaseMoment.thirdLikeReceived);
    if (shown) await _markDone(_thirdLikeKey);
    return shown;
  }

  /// The match sheet was closed. The first one this phone ever shows is the
  /// member's first match: unless they went on to the chat, that is the offer
  /// of [PurchaseMoment.firstMatch]. Later matches never offer anything.
  static Future<bool> afterMatchSheet(
    BuildContext context, {
    required bool openedChat,
  }) async {
    if (PremiumGate.isPremium || await _alreadyDone(_firstMatchKey)) {
      return false;
    }
    await _markDone(_firstMatchKey);
    if (openedChat || !context.mounted) return false;
    return offer(context, PurchaseMoment.firstMatch);
  }

  /// For an offer that already has its own sheet (the daily likes limit):
  /// measures it the same way and counts it as the day's offer for [moment],
  /// without showing a second one. [show] returns true when the member chose to
  /// discover mazl+.
  static Future<bool> measure(
    BuildContext context,
    PurchaseMoment moment,
    Future<bool> Function() show,
  ) {
    if (PremiumGate.isPremium) return show();
    _claimed[moment] = _dayKey();
    unawaited(_remember(moment));
    return _measured(context, moment, show);
  }

  static Future<bool> _measured(
    BuildContext context,
    PurchaseMoment moment,
    Future<bool> Function() show,
  ) async {
    trackEvent(context, AnalyticsEvent.purchaseMomentShown(moment.name));
    final accepted = await show();
    if (context.mounted) {
      trackEvent(
        context,
        accepted
            ? AnalyticsEvent.purchaseMomentAccepted(moment.name)
            : AnalyticsEvent.purchaseMomentDismissed(moment.name),
      );
    }
    return accepted;
  }

  /// Claims the day for [moment]; false when it was already taken.
  static Future<bool> _claimToday(PurchaseMoment moment) async {
    final today = _dayKey();
    if (_claimed[moment] == today) return false;
    _claimed[moment] = today;
    try {
      final stored = (await preferences()).getString(
        '$_keyPrefix${moment.name}',
      );
      if (stored == today) return false;
    } on Object catch (e) {
      debugPrint('PurchaseMoments: storage unreadable (${e.runtimeType})');
      return true;
    }
    return true;
  }

  static Future<bool> _alreadyDone(String key) async {
    if (_done.contains(key)) return true;
    try {
      if ((await preferences()).getBool(key) ?? false) {
        _done.add(key);
        return true;
      }
    } on Object catch (e) {
      debugPrint('PurchaseMoments: storage unreadable (${e.runtimeType})');
    }
    return false;
  }

  static Future<void> _markDone(String key) async {
    _done.add(key);
    try {
      await (await preferences()).setBool(key, true);
    } on Object catch (e) {
      debugPrint('PurchaseMoments: storage unwritable (${e.runtimeType})');
    }
  }

  static Future<void> _remember(PurchaseMoment moment) async {
    try {
      await (await preferences()).setString(
        '$_keyPrefix${moment.name}',
        _dayKey(),
      );
    } on Object catch (e) {
      debugPrint('PurchaseMoments: storage unwritable (${e.runtimeType})');
    }
  }

  static String _dayKey() {
    final now = clock();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }
}
