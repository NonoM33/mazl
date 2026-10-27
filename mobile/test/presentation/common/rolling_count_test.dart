import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/common/widgets/rolling_count/rolling_count.dart';
import 'package:mazl/presentation/features/matching/screens/matches_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../../support/reduce_motion_support.dart';

/// Shows [RollingCount] with a value the test can change.
class _Harness extends StatefulWidget {
  const _Harness(this.start, {this.sentence});

  final int start;
  final String Function(int value)? sentence;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int value = widget.start;

  void set(int next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: RollingCount(
        value: value,
        sentence: widget.sentence?.call(value),
        style: const TextStyle(fontSize: 20),
      ),
    ),
  );
}

Future<_HarnessState> _show(
  WidgetTester tester,
  int start, {
  String Function(int value)? sentence,
  bool reduced = false,
}) async {
  if (reduced) setReduceMotion(tester, on: true);
  await tester.pumpWidget(
    reduceMotionApp(home: _Harness(start, sentence: sentence)),
  );
  return tester.state<_HarnessState>(find.byType(_Harness));
}

/// Changes the value, builds it, and lets the roll take its first frame (a
/// ticker starts counting on the frame after the one that created it).
Future<void> _roll(WidgetTester tester, Object state, int next) async {
  if (state is _HarnessState) state.set(next);
  if (state is _SectionState) state.set(next);
  await tester.pump();
  await tester.pump(Duration.zero);
}

/// Where the glyph under [key] is drawn (the cell moves it at paint time).
Offset _top(WidgetTester tester, String key) => tester.getTopLeft(
  find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Text)),
);

void main() {
  const half = Duration(milliseconds: 120);
  const still1 = ValueKey('rolling-still-1');

  testWidgets('12 to 13: only the units digit rolls, upward', (tester) async {
    final harness = await _show(tester, 12);
    await _roll(tester, harness, 13);
    final outStart = _top(tester, 'rolling-out-0');
    final inStart = _top(tester, 'rolling-in-0');
    final tensStart = tester.getTopLeft(find.byKey(still1));

    await tester.pump(half);

    expect(find.byKey(still1), findsOneWidget);
    expect(_top(tester, 'rolling-out-0').dy, lessThan(outStart.dy));
    expect(_top(tester, 'rolling-in-0').dy, lessThan(inStart.dy));
    expect(tester.getTopLeft(find.byKey(still1)), tensStart);
    expect(find.byKey(const ValueKey('rolling-out-1')), findsNothing);
  });

  testWidgets('13 to 12: the units digit rolls downward', (tester) async {
    final harness = await _show(tester, 13);
    await _roll(tester, harness, 12);
    final outStart = _top(tester, 'rolling-out-0');
    final inStart = _top(tester, 'rolling-in-0');

    await tester.pump(half);

    expect(_top(tester, 'rolling-out-0').dy, greaterThan(outStart.dy));
    expect(_top(tester, 'rolling-in-0').dy, greaterThan(inStart.dy));
    expect(find.byKey(still1), findsOneWidget);
  });

  testWidgets('9 to 10: a digit appears and the width ends as « 10 »', (
    tester,
  ) async {
    final harness = await _show(tester, 9);
    final nine = tester.getSize(find.byType(RollingCount)).width;
    await _roll(tester, harness, 10);
    await tester.pump(half);
    final middle = tester.getSize(find.byType(RollingCount)).width;
    expect(find.byKey(const ValueKey('rolling-in-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('rolling-out-1')), findsNothing);

    await tester.pumpAndSettle();
    final ten = tester.getSize(find.byType(RollingCount)).width;

    expect(middle, greaterThan(nine));
    expect(middle, lessThan(ten));
    expect(ten, nine * 2);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('first display: nothing rolls', (tester) async {
    await _show(tester, 12);
    await tester.pump();

    expect(find.byKey(const ValueKey('rolling-out-0')), findsNothing);
    expect(find.byKey(const ValueKey('rolling-in-0')), findsNothing);
    expect(find.text('12'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the screen reader reads the final number once', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await _show(tester, 12);
    await _roll(tester, harness, 13);
    await tester.pump(half);

    expect(find.bySemanticsLabel('13'), findsOneWidget);
    expect(find.bySemanticsLabel('12'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('13'), findsOneWidget);
    expect(find.bySemanticsLabel('12'), findsNothing);
    handle.dispose();
  });

  testWidgets('a number inside a sentence keeps the sentence in one piece', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final harness = await _show(
      tester,
      12,
      sentence: (n) => 'Voir les $n autres',
    );
    await _roll(tester, harness, 13);
    await tester.pump(half);

    expect(find.bySemanticsLabel('Voir les 13 autres'), findsOneWidget);
    expect(find.byKey(const ValueKey('rolling-out-0')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Voir les 13 autres'), findsOneWidget);
    expect(find.byKey(const ValueKey('rolling-out-0')), findsNothing);
    handle.dispose();
  });

  testWidgets('Reduce Motion on: the new number appears at once', (
    tester,
  ) async {
    final harness = await _show(tester, 12, reduced: true);
    harness.set(13);
    await tester.pump();

    expect(find.text('13'), findsOneWidget);
    expect(find.byKey(const ValueKey('rolling-out-0')), findsNothing);
    expect(find.byKey(const ValueKey('rolling-in-0')), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the roll lasts MazlMotion.rollingCount, then rests', (
    tester,
  ) async {
    final harness = await _show(tester, 5);
    await _roll(tester, harness, 6);
    await tester.pump(
      MazlMotion.rollingCount - const Duration(milliseconds: 20),
    );
    expect(find.byKey(const ValueKey('rolling-out-0')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byKey(const ValueKey('rolling-out-0')), findsNothing);
    expect(find.text('6'), findsOneWidget);
  });

  group('the translated sentence keeps its words around the number', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> openMatches(WidgetTester tester, Locale locale) async {
      await pumpLocalized(
        tester,
        MatchesScreen(apiService: _FakeApi()),
        locale: locale,
        size: const Size(360, 2000),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('French: « Ils vous ont aimé · 9 » and the button', (
      tester,
    ) async {
      await openMatches(tester, const Locale('fr'));

      expect(find.text('ILS VOUS ONT AIMÉ · 9'), findsOneWidget);
      expect(find.textContaining('Voir les 5 autres'), findsOneWidget);
    });

    testWidgets('Hebrew: the words stay, the digits read left to right', (
      tester,
    ) async {
      await openMatches(tester, const Locale('he'));

      expect(find.text('אהבו אותך · 9'), findsOneWidget);
      expect(find.textContaining('לראות עוד 5'), findsOneWidget);
    });

    for (final (locale, words) in const [
      (Locale('fr'), 'ILS VOUS ONT AIMÉ'),
      (Locale('he'), 'אהבו אותך'),
    ]) {
      testWidgets(
        '${locale.languageCode}: the words stay while the digits roll',
        (tester) async {
          final handle = tester.ensureSemantics();
          await pumpLocalized(tester, const _Section(), locale: locale);
          final state = tester.state<_SectionState>(find.byType(_Section));
          await _roll(tester, state, 10);
          await tester.pump(half);

          expect(find.byKey(const ValueKey('rolling-in-1')), findsOneWidget);
          expect(find.bySemanticsLabel('$words · 10'), findsOneWidget);
          final inline = tester.widget<RichText>(
            find
                .descendant(
                  of: find.byType(SectionLabel),
                  matching: find.byType(RichText),
                )
                .first,
          );
          expect(
            inline.text.toPlainText(includePlaceholders: false),
            contains(words),
          );
          final digit = _top(tester, 'rolling-in-1');
          final label = tester.getRect(find.byType(SectionLabel));
          expect(
            label.contains(Offset(digit.dx + 1, label.center.dy)),
            isTrue,
            reason: 'the digits sit inside the label, between its words',
          );

          await tester.pumpAndSettle();

          expect(find.text('$words · 10'), findsOneWidget);
          handle.dispose();
        },
      );
    }
  });
}

class _Section extends StatefulWidget {
  const _Section();

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  int value = 9;

  void set(int next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SectionLabel(context.l10n.likesSection('$value'), count: value),
  );
}

class _FakeApi implements ApiService {
  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getMatches() async =>
      ApiResponse.success(const []);

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async =>
      ApiResponse.success(
        LikesData(
          count: 9,
          isPremium: true,
          likes: [
            for (var i = 1; i <= 4; i++)
              LikeProfile(
                userId: i,
                displayName: 'Noa$i',
                likedAt: DateTime(2026, 10),
              ),
          ],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeApi: ${invocation.memberName}');
}
