import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Regression (seen on the simulator 2026-10-23): after restarting the app, the
// demo sign-in showed « Le mode couple a pris fin. » although nobody left. The
// couple cache survived in SharedPreferences while the demo restarts empty, so
// the first sync concluded that the couple had ended.
void main() {
  tearDown(DevSession.stop);

  test('a demo sign-in starts with no couple cached from a previous run', () async {
    SharedPreferences.setMockInitialValues({
      'couple_mode_enabled': true,
      'couple_data': jsonEncode({'coupleId': 7, 'partnerId': 201, 'partnerName': 'Noémie'}),
    });
    await CoupleService().initialize();
    expect(CoupleService().isCoupleModeEnabled, isTrue, reason: 'stale cache loaded, as after a restart');

    final ended = <CoupleFlowEvent>[];
    final sub = CoupleService().events.listen(ended.add);
    await AuthService().signInAsDemo();
    await CoupleService().refresh();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(CoupleService().isCoupleModeEnabled, isFalse);
    expect(ended.whereType<CoupleEnded>(), isEmpty, reason: 'nobody ended anything');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('couple_mode_enabled') ?? false, isFalse);
  });

  test('in demo a pending request is re-read every 2 s (no realtime channel)', () {
    DevSession.start();
    expect(CoupleService().pollInterval, const Duration(seconds: 2));
    DevSession.stop();
    expect(CoupleService().pollInterval, const Duration(seconds: 10));
  });
}
