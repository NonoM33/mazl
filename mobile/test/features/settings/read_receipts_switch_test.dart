import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/premium/read_receipts_api.dart';
import 'package:mazl/presentation/features/settings/widgets/read_receipts_switch.dart';

import '../../helpers/l10n_helpers.dart';

class _FakeApi implements ReadReceiptsApi {
  _FakeApi({this.held = true});

  /// What the « server » holds.
  bool held;
  Object? loadError;
  Object? setError;
  Completer<void>? gate;
  final calls = <String>[];

  @override
  Future<bool> load() async {
    calls.add('load');
    final error = loadError;
    if (error != null) throw error;
    return held;
  }

  @override
  Future<bool> set(bool enabled) async {
    calls.add('set:$enabled');
    await gate?.future;
    final error = setError;
    if (error != null) throw error;
    held = enabled;
    return held;
  }
}

const _network = ReadReceiptsException(ReadReceiptsErrorKind.network);

Finder get _switch => find.byType(Switch);

bool _isOn(WidgetTester tester) => tester.widget<Switch>(_switch).value;

Future<void> _pump(WidgetTester tester, _FakeApi api) async {
  await pumpLocalized(tester, Scaffold(body: ReadReceiptsSwitch(api: api)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the value the server holds, on by default', (
    tester,
  ) async {
    final api = _FakeApi(held: true);
    await _pump(tester, api);
    expect(find.text('Envoyer les confirmations de lecture'), findsOneWidget);
    expect(_isOn(tester), isTrue);
    expect(api.calls, ['load']);
  });

  testWidgets('shows « off » when the server holds off', (tester) async {
    await _pump(tester, _FakeApi(held: false));
    expect(_isOn(tester), isFalse);
  });

  testWidgets('a tap calls the API and keeps the value it answers', (
    tester,
  ) async {
    final api = _FakeApi(held: true);
    await _pump(tester, api);
    await tester.tap(_switch);
    await tester.pumpAndSettle();
    expect(api.calls, ['load', 'set:false']);
    expect(_isOn(tester), isFalse);
    await tester.tap(_switch);
    await tester.pumpAndSettle();
    expect(api.calls.last, 'set:true');
    expect(_isOn(tester), isTrue);
  });

  testWidgets(
    'a refusal puts the switch back on the server state and says so',
    (tester) async {
      final api = _FakeApi(held: true)..setError = _network;
      await _pump(tester, api);
      await tester.tap(_switch);
      await tester.pump();
      await tester.pumpAndSettle();
      // The server still holds « on »: the switch is back on it.
      expect(_isOn(tester), isTrue);
      expect(api.calls, ['load', 'set:false', 'load']);
      expect(
        find.text('Impossible de modifier ce réglage. Réessayez.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'when the server state cannot be re-read, the previous value returns',
    (tester) async {
      final api = _FakeApi(held: true);
      await _pump(tester, api);
      api
        ..setError = _network
        ..loadError = _network;
      await tester.tap(_switch);
      await tester.pumpAndSettle();
      expect(_isOn(tester), isTrue);
      expect(
        find.text('Impossible de modifier ce réglage. Réessayez.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the switch does not move on a second tap while a save is running',
    (tester) async {
      final gate = Completer<void>();
      final api = _FakeApi(held: true)..gate = gate;
      await _pump(tester, api);
      await tester.tap(_switch);
      await tester.pump();
      await tester.tap(_switch, warnIfMissed: false);
      await tester.pump();
      expect(api.calls.where((c) => c.startsWith('set')), ['set:false']);
      gate.complete();
      await tester.pumpAndSettle();
      expect(_isOn(tester), isFalse);
    },
  );

  testWidgets('a load failure disables the switch; tapping the row retries', (
    tester,
  ) async {
    final api = _FakeApi(held: false)..loadError = _network;
    await _pump(tester, api);
    expect(tester.widget<Switch>(_switch).onChanged, isNull);
    expect(
      find.text("Réglage indisponible pour l'instant. Touchez pour réessayer."),
      findsOneWidget,
    );
    api.loadError = null;
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_isOn(tester), isFalse);
    expect(tester.widget<Switch>(_switch).onChanged, isNotNull);
  });

  testWidgets(
    'the row is at least 44 pt tall and tappable on its whole width',
    (tester) async {
      await _pump(tester, _FakeApi());
      final box = tester.getRect(find.byType(ListTile));
      expect(box.height, greaterThanOrEqualTo(44));
      expect(box.width, 360);
    },
  );
}
