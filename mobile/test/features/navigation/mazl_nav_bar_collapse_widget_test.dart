import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';
import 'package:mazl/presentation/features/navigation/widgets/nav_bar_collapse.dart';
import '../../helpers/l10n_helpers.dart';

const _items = [
  MazlNavItem(icon: LucideIcons.layers, label: 'Découvrir'),
  MazlNavItem(icon: LucideIcons.heart, label: 'Matchs'),
  MazlNavItem(icon: LucideIcons.user, label: 'Profil'),
];

const _screen = Size(390, 844);
const _safeBottom = 34.0;

/// A tab page (a long list) under the bar, wired like MainNavigationScreen.
Future<({NavBarCollapseController nav, List<int> taps, List<String> bodyTaps})> _pump(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final nav = NavBarCollapseController();
  final taps = <int>[];
  final bodyTaps = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: const MediaQueryData(size: _screen, padding: EdgeInsets.only(bottom: _safeBottom)),
        child: Scaffold(
          extendBody: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: nav.handleNotification,
            child: ListView.builder(
              itemCount: 200,
              itemExtent: 60,
              itemBuilder: (_, i) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => bodyTaps.add('row $i'),
                child: Text('row $i'),
              ),
            ),
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: nav,
            builder: (_, _) => MazlNavBar(
              items: _items,
              currentIndex: 1,
              onTap: (i) {
                taps.add(i);
                nav.expand();
              },
              collapsed: nav.collapsed,
              onExpand: nav.expand,
            ),
          ),
        ),
      ),
    ),
  );
  return (nav: nav, taps: taps, bodyTaps: bodyTaps);
}

Rect _bar(WidgetTester tester) => tester.getRect(find.byKey(const Key('mazl-nav-bar')));

Future<void> _scrollDown(WidgetTester tester) async {
  await tester.drag(find.text('row 3'), const Offset(0, -300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scrolling down folds the bar into a round pill on the left, still clear of the system area', (tester) async {
    await _pump(tester);
    expect(_bar(tester).width, greaterThan(300));

    await _scrollDown(tester);
    final pill = _bar(tester);
    expect(pill.width, MazlNavBar.barHeight);
    expect(pill.height, MazlNavBar.barHeight);
    expect(pill.left, greaterThanOrEqualTo(MazlNavBar.sideMargin));
    expect(_screen.height - _safeBottom - pill.bottom, greaterThanOrEqualTo(MazlNavBar.gap));
  });

  testWidgets('folded, only the current tab is offered, as a button that unfolds the bar', (tester) async {
    final t = await _pump(tester);
    await _scrollDown(tester);

    final semantics = tester.ensureSemantics();
    // The real semantics tree, i.e. what VoiceOver / TalkBack reads.
    expect(find.semantics.byLabel('Afficher les onglets'), findsOne);
    expect(find.semantics.byLabel('Découvrir'), findsNothing);
    expect(find.semantics.byLabel('Profil'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Afficher les onglets'));
    await tester.pumpAndSettle();
    expect(t.nav.collapsed, isFalse);
    expect(t.taps, isEmpty, reason: 'unfolding does not change tab');
    expect(_bar(tester).width, greaterThan(300));
    expect(find.semantics.byLabel('Profil'), findsOne);
    expect(find.semantics.byLabel('Afficher les onglets'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a quick flick back up unfolds the bar', (tester) async {
    final t = await _pump(tester);
    await tester.drag(find.text('row 3'), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(t.nav.collapsed, isTrue);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 2500);
    await tester.pumpAndSettle();
    expect(t.nav.collapsed, isFalse);
  });

  testWidgets('folded, a touch beside the pill reaches the page', (tester) async {
    final t = await _pump(tester);
    await _scrollDown(tester);
    final pill = _bar(tester);

    await tester.tapAt(Offset(_screen.width - 60, pill.center.dy));
    expect(t.bodyTaps, isNotEmpty);
    expect(t.nav.collapsed, isTrue);
  });

  testWidgets('expanded, tapping a tab still changes tab', (tester) async {
    final t = await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Profil'));
    expect(t.taps, [2]);
  });

  testWidgets('expanded, the hidden pill does not swallow the first tab', (tester) async {
    final t = await _pump(tester);
    await _scrollDown(tester);
    t.nav.expand();
    await tester.pumpAndSettle();
    // The pill sits exactly over the first tab when it is hidden.
    await tester.tapAt(_bar(tester).centerLeft + const Offset(MazlNavBar.barHeight / 2, 0));
    expect(t.taps, [0]);
  });
}
