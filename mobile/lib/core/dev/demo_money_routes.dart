import 'demo_premium_routes.dart';
import 'demo_routes.dart';
import 'demo_store.dart';

/// The read receipts setting, the best time to boost and the scheduled Boost
/// in demo mode: same shapes and refusals as the server
/// (docs/premium/MONETISATION.md §4 and §8). Nothing leaves the device.
abstract final class DemoMoneyRoutes {
  static bool _sendReadReceipts = true;
  static DateTime? _scheduledAt;

  /// Back to a new session: receipts on, nothing scheduled.
  static void reset() {
    _sendReadReceipts = true;
    _scheduledAt = null;
  }

  /// The next Saturday at 21:00 local time, still to come and so within the 7
  /// days the server accepts: « samedi 21 h, après Shabbat ».
  static DateTime _bestTime() {
    final now = DemoStore.clock().toLocal();
    var day = DateTime(now.year, now.month, now.day, 21);
    while (day.weekday != DateTime.saturday || !day.isAfter(now)) {
      day = DateTime(day.year, day.month, day.day + 1, 21);
    }
    return day.toUtc();
  }

  static Map<String, dynamic> _bestTimeData() {
    final best = _bestTime();
    return {
      'city': 'Paris',
      'best_time': {
        'starts_at': best.toIso8601String(),
        'weekday': best.weekday,
        'hour': best.hour,
      },
      'scheduled_at': _scheduledAt?.toIso8601String(),
    };
  }

  static DemoReply _schedule(DemoRequest request, RegExpMatch match) {
    final at = DateTime.tryParse('${request.body['at']}')?.toUtc();
    final now = DemoStore.clock().toUtc();
    if (at == null ||
        !at.isAfter(now) ||
        at.isAfter(now.add(const Duration(days: 7)))) {
      return const DemoReply({
        'success': false,
        'error': 'invalid_time',
      }, status: 400);
    }
    if (_scheduledAt != null) {
      return const DemoReply({
        'success': false,
        'error': 'already_scheduled',
      }, status: 409);
    }
    if (DemoStore.boostsLeft <= 0) {
      return const DemoReply({
        'success': false,
        'error': 'boosts_exhausted',
      }, status: 402);
    }
    _scheduledAt = at;
    return DemoReply({
      'success': true,
      'data': {'scheduled_at': at.toIso8601String()},
    }, status: 201);
  }

  static DemoReply _json(Object body) => DemoReply(body);

  static final List<DemoRoute> routes = [
    DemoRoute(
      'GET',
      '/api/premium/settings',
      (r, m) => _json({
        'success': true,
        'data': {
          ...DemoPremiumRoutes.settings(),
          'send_read_receipts': _sendReadReceipts,
        },
      }),
    ),
    DemoRoute('PUT', '/api/profile/read-receipts', (r, m) {
      final enabled = r.body['enabled'];
      if (enabled is! bool) {
        return const DemoReply({
          'success': false,
          'error': 'invalid_body',
        }, status: 400);
      }
      _sendReadReceipts = enabled;
      return _json({
        'success': true,
        'data': {'send_read_receipts': _sendReadReceipts},
      });
    }),
    DemoRoute(
      'GET',
      '/api/boost/best-time',
      (r, m) => _json({'success': true, 'data': _bestTimeData()}),
    ),
    DemoRoute('POST', '/api/boost/schedule', _schedule),
    DemoRoute('DELETE', '/api/boost/schedule', (r, m) {
      _scheduledAt = null;
      return _json({
        'success': true,
        'data': {'scheduled_at': null},
      });
    }),
  ];
}
