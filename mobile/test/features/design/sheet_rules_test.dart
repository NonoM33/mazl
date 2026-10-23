import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_sheet.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';

// Paid on 2026-10-23: the MAZL+ sheet opened UNDER the floating tab bar (its
// buttons hidden) and showed two drag handles. Both came from each screen
// calling showModalBottomSheet itself. These rules make it impossible again.

const _screen = Size(390, 844);
const _handle = Size(36, 5);

/// Same structure as the app: the tab pages live in a nested navigator (the
/// StatefulShellRoute branch), the floating bar belongs to the outer Scaffold.
Future<void> _pumpShell(WidgetTester tester, void Function(BuildContext) open) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  // At the view level, like a real phone: the ROOT navigator sees it too.
  tester.view.padding = const FakeViewPadding(bottom: 34);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (_) => Scaffold(
          extendBody: true,
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Center(child: TextButton(onPressed: () => open(context), child: const Text('open'))),
              ),
            ),
          ),
          bottomNavigationBar: MazlNavBar(
            items: const [
              MazlNavItem(icon: LucideIcons.layers, label: 'Découvrir'),
              MazlNavItem(icon: LucideIcons.user, label: 'Profil'),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Widget _content() => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Text('Super Likes'),
    const SizedBox(height: 40),
    ElevatedButton(onPressed: () {}, child: const Text('Passer à MAZL+')),
    TextButton(onPressed: () {}, child: const Text('Pas maintenant')),
  ],
);

/// True when a tap at the centre of [finder] reaches it (nothing drawn on top).
bool _reachable(WidgetTester tester, Finder finder) {
  final target = tester.renderObject(finder);
  final result = HitTestResult();
  tester.binding.hitTestInView(result, tester.getCenter(finder), tester.view.viewId);
  return result.path.any((entry) => entry.target == target);
}

int _handles(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderBox>()
    .where((box) => box.hasSize && box.size == _handle && box is RenderDecoratedBox)
    .length;

void main() {
  group('opened from a tab', () {
    testWidgets('CONTROL: with a raw showModalBottomSheet the tab bar is drawn over the sheet (the bug)', (tester) async {
      await _pumpShell(tester, (context) => showModalBottomSheet<void>(context: context, builder: (_) => _content()));
      expect(find.text('Pas maintenant'), findsOneWidget, reason: 'the sheet is open');
      expect(_reachable(tester, find.byKey(const Key('mazl-nav-bar'))), isTrue);
    });

    testWidgets('showMazlSheet covers the tab bar: every button of the sheet is reachable', (tester) async {
      await _pumpShell(tester, (context) => showMazlSheet<void>(context, builder: (_) => _content()));
      expect(_reachable(tester, find.text('Passer à MAZL+')), isTrue);
      expect(_reachable(tester, find.text('Pas maintenant')), isTrue);
      expect(_reachable(tester, find.byKey(const Key('mazl-nav-bar'))), isFalse);
    });

    testWidgets('exactly one drag handle, the design system one (36x5)', (tester) async {
      await _pumpShell(tester, (context) => showMazlSheet<void>(context, builder: (_) => _content()));
      expect(_handles(tester), 1);
    });

    testWidgets('the content clears the home indicator', (tester) async {
      await _pumpShell(tester, (context) => showMazlSheet<void>(context, builder: (_) => _content()));
      final last = tester.getRect(find.text('Pas maintenant'));
      expect(_screen.height - last.bottom, greaterThanOrEqualTo(34 + MazlSheetBody.padding));
    });
  });

  group('source rules', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    String relative(File f) => f.path.replaceFirst(RegExp(r'^.*?lib/'), 'lib/');

    test('bottom sheets are opened only through showMazlSheet', () {
      final direct = RegExp(r'\bshow(Modal)?BottomSheet\s*(<[^>]*>)?\s*\(');
      final offenders = [
        for (final f in sources)
          if (!f.path.endsWith('mazl_sheet.dart') && direct.hasMatch(f.readAsStringSync())) relative(f),
      ];
      expect(offenders, isEmpty, reason: 'use showMazlSheet: root navigator + the single theme handle');
    });

    test('popup menus open on the root navigator, above the tab bar', () {
      final menu = RegExp(r'\b(PopupMenuButton\s*(<[^>]*>)?\s*\(|showMenu\s*(<[^>]*>)?\s*\()');
      final offenders = <String>[];
      for (final f in sources) {
        final text = f.readAsStringSync();
        for (final m in menu.allMatches(text)) {
          // The arguments of this call: up to the first line closing it at
          // the same indentation, a generous window is enough here.
          final window = text.substring(m.start, (m.start + 600).clamp(0, text.length));
          if (!window.contains('useRootNavigator: true')) {
            offenders.add('${relative(f)}:${text.substring(0, m.start).split('\n').length}');
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('no hand-drawn drag handle (the theme draws the only one)', () {
      // A small bar that is NOT a handle says so on the line above:
      // `// not a drag handle: <what it is>`.
      final handle = RegExp(r'(// not a drag handle[^\n]*\n\s*)?width:\s*(\d+)(?:\.0)?,\s*\n\s*height:\s*(\d+)(?:\.0)?,');
      final offenders = <String>[];
      for (final f in sources) {
        final text = f.readAsStringSync();
        for (final m in handle.allMatches(text)) {
          if (m.group(1) != null) continue;
          final w = int.parse(m.group(2)!);
          final h = int.parse(m.group(3)!);
          if (w >= 28 && w <= 60 && h >= 3 && h <= 6) {
            offenders.add('${relative(f)}:${text.substring(0, m.start).split('\n').length}');
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
