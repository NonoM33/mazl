import 'demo_routes.dart';
import 'demo_store.dart';

/// The mazl+ settings (passport, discreet mode), the Super Like word and the
/// undo in demo mode: same shapes and refusals as the server
/// (docs/premium/MONETISATION.md §2, §3, §5 and §7). Nothing leaves the device.
///
/// The demo member is a subscriber, like everywhere else in the demo
/// (`/api/likes/allowance`, `/api/discover/filters`): [isPlus] is true.
abstract final class DemoPremiumRoutes {
  /// Whether the demo member holds mazl+. Tests turn it off to see the
  /// refusals.
  static bool isPlus = true;

  static Map<String, dynamic>? _passport;
  static bool _incognito = false;

  /// The last pass or like that can still be taken back.
  static ({int userId, String action, bool matched, DateTime at})? _last;
  static int _freeUndosUsed = 0;
  static DateTime? _undosDay;

  /// Back to a new session: own city, discreet mode off, nothing to undo.
  static void reset() {
    isPlus = true;
    _passport = null;
    _incognito = false;
    _last = null;
    _freeUndosUsed = 0;
    _undosDay = null;
  }

  /// The `data` of `GET /api/premium/settings`.
  static Map<String, dynamic> settings() => {
    'is_plus': isPlus,
    'passport': _passport,
    'incognito': _incognito,
    // The read receipts are kept by demo_money_routes.dart, which overrides this.
    'send_read_receipts': true,
  };

  static const _noteMax = 140;
  static final _link = RegExp(
    r'https?://|www\.|\S+@\S+\.\S+',
    caseSensitive: false,
  );

  /// The server's refusal of a swipe whose `note` it does not accept, or null.
  static DemoReply? checkNote(Map<String, dynamic> body) {
    if (!body.containsKey('note')) return null;
    if (body['action'] != 'super_like') {
      return _refused('note_requires_super_like', 400);
    }
    final note = body['note'];
    final text = note is String ? note.trim() : '';
    if (text.isEmpty || text.length > _noteMax || _link.hasMatch(text)) {
      return _refused('invalid_note', 400);
    }
    return null;
  }

  /// Remembers the swipe the undo would take back.
  static void recordSwipe(Map<String, dynamic> body, {required bool matched}) {
    final user = body['target_user_id'];
    final action = body['action'];
    if (user is! int || action is! String) return;
    _last = (
      userId: user,
      action: action,
      matched: matched,
      at: DemoStore.clock(),
    );
  }

  static DemoReply _refused(String code, int status) =>
      DemoReply({'success': false, 'error': code}, status: status);

  static DemoReply _json(Object body) => DemoReply(body);

  static DemoReply _passportRoute(DemoRequest r, RegExpMatch m) {
    final body = r.body;
    // A JSON `null` body (turn off) reaches the router as an empty object.
    if (body.isEmpty) {
      _passport = null;
      return _json({
        'success': true,
        'data': {'passport': null},
      });
    }
    final city = body['city'];
    final lat = body['latitude'];
    final lng = body['longitude'];
    if (city is! String ||
        city.trim().isEmpty ||
        city.length > 80 ||
        lat is! num ||
        lng is! num) {
      return _refused('invalid_body', 400);
    }
    if (!isPlus) return _refused('mazl_plus_required', 402);
    _passport = {
      'city': city.trim(),
      'latitude': lat.toDouble(),
      'longitude': lng.toDouble(),
    };
    return _json({
      'success': true,
      'data': {'passport': _passport},
    });
  }

  static DemoReply _incognitoRoute(DemoRequest r, RegExpMatch m) {
    final enabled = r.body['enabled'];
    if (enabled is! bool) return _refused('invalid_body', 400);
    if (enabled && !isPlus) return _refused('mazl_plus_required', 402);
    _incognito = enabled;
    return _json({
      'success': true,
      'data': {'incognito': _incognito},
    });
  }

  static DemoReply _undoRoute(DemoRequest r, RegExpMatch m) {
    final now = DemoStore.clock();
    final last = _last;
    if (last == null || now.difference(last.at) > const Duration(minutes: 10)) {
      return _refused('nothing_to_undo', 404);
    }
    if (last.action == 'super_like' || last.matched) {
      return _refused('undo_not_possible', 409);
    }
    final today = DateTime(now.year, now.month, now.day);
    if (_undosDay != today) {
      _undosDay = today;
      _freeUndosUsed = 0;
    }
    if (!isPlus && _freeUndosUsed >= 1) {
      return _refused('undo_limit_reached', 402);
    }
    if (!isPlus) _freeUndosUsed++;
    _last = null;
    return _json({
      'success': true,
      'data': {
        'target_user_id': last.userId,
        'action': last.action,
        'remaining_free_undos': isPlus ? null : 1 - _freeUndosUsed,
      },
    });
  }

  static final List<DemoRoute> routes = [
    DemoRoute('PUT', '/api/discover/passport', _passportRoute),
    DemoRoute('PUT', '/api/profile/incognito', _incognitoRoute),
    DemoRoute('POST', '/api/swipes/undo', _undoRoute),
  ];
}
