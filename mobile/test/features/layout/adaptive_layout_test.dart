import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/chat/voice_impl.dart';
import 'package:mazl/core/layout/adaptive_detail.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/layout/window_size.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/router/route_transitions.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_sheet.dart';
import 'package:mazl/presentation/features/chat/chat_providers.dart';
import 'package:mazl/presentation/features/chat/screens/chat_conversation_screen.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';
import 'package:mazl/presentation/features/navigation/screens/main_navigation_screen.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';

import '../../helpers/l10n_helpers.dart';
import '../chat/chat_test_support.dart';

// The app's frame at the two widths of the foldable iPhone: the outer display
// is compact, the inner display is regular. Folding is a change of width, so
// every "fold" below is `tester.view.physicalSize` changing under a live app.

const _compact = Size(390, 844);
const _regular = Size(700, 960);
const _tabs = ['discover', 'matches', 'chat', 'events', 'profile'];
const _tabLabels = ['Découvrir', 'Matchs', 'Messages', 'Événements', 'Profil'];

/// A tab page: a title, and a button at the very end of the row so that any
/// page drawn into the unsafe area shows up.
class _TabPage extends StatefulWidget {
  const _TabPage(this.name, {this.openTargets = const {}});

  final String name;

  /// Button label -> how to open it.
  final Map<String, void Function(BuildContext)> openTargets;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    // Like the real screens: only the top inset is theirs, the sides are the shell's.
    body: Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('page ${widget.name}')),
              TextButton(
                key: Key('count-${widget.name}'),
                onPressed: () => setState(() => taps++),
                child: Text('n$taps'),
              ),
            ],
          ),
          for (final entry in widget.openTargets.entries)
            ListTile(title: Text(entry.key), onTap: () => entry.value(context)),
        ],
      ),
    ),
  );
}

class _Harness {
  _Harness() : chat = ChatHarness();

  final ChatHarness chat;
  late final GoRouter router;
  String? lastDetail;

  Widget _detail(BuildContext context, DetailTarget target) => switch (target) {
    ChatDetail() => ChatConversationScreen(
      conversationId: conversationId,
      otherUser: ConversationUser(userId: other, displayName: 'Noémie'),
      onBack: () => context.pop(),
    ),
    MatchProfileDetail(:final userId) => Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Row(
          children: [
            Expanded(child: Text('profil $userId')),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('fermer'),
            ),
          ],
        ),
      ),
    ),
  };

  GoRouter buildRouter(String initial) => router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initial,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainNavigationScreen(
          navigationShell: shell,
          buildDetail: _detail,
          prefetch: () async {},
        ),
        branches: [
          for (final name in _tabs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/$name',
                  builder: (context, state) => switch (name) {
                    'chat' => _TabPage(
                      name,
                      openTargets: {
                        'Noémie': (c) => c.go('/chat/$conversationId'),
                      },
                    ),
                    'matches' => _TabPage(
                      name,
                      openTargets: {
                        'Voir le profil 7': (c) => c.push('/matches/profile/7'),
                      },
                    ),
                    _ => _TabPage(name),
                  },
                  routes: [
                    if (name == 'chat')
                      GoRoute(
                        path: ':id',
                        parentNavigatorKey: rootKey,
                        pageBuilder: (context, state) {
                          final target = ChatDetail(
                            state.pathParameters['id']!,
                          );
                          return AdaptiveDetailPage(
                            key: state.pageKey,
                            target: target,
                            child: _detail(context, target),
                            transitionsBuilder: slideLeftMotion,
                          );
                        },
                      ),
                    if (name == 'matches')
                      GoRoute(
                        path: 'profile/:userId',
                        parentNavigatorKey: rootKey,
                        pageBuilder: (context, state) {
                          final target = MatchProfileDetail(
                            state.pathParameters['userId']!,
                          );
                          return AdaptiveDetailPage(
                            key: state.pageKey,
                            target: target,
                            child: _detail(context, target),
                            transitionsBuilder: heroMotion,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );

  final rootKey = GlobalKey<NavigatorState>();

  Future<void> pump(
    WidgetTester tester, {
    Size size = _compact,
    Locale locale = kTestLocale,
    FakeViewPadding padding = FakeViewPadding.zero,
    String initial = '/discover',
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = padding;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWith((ref, id) => chat.actions),
          voiceRecorderProvider.overrideWithValue(chat.recorder),
          voicePlayerProvider.overrideWithValue(chat.player),
          chatMediaPickerProvider.overrideWithValue(chat.picker),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          routerConfig: buildRouter(initial),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// Folds or unfolds the device under the running app.
Future<void> _resize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
}

Finder _railIcon(IconData icon) => find.descendant(
  of: find.byKey(const Key('mazl-nav-rail')),
  matching: find.byIcon(icon),
);

Rect _rail(WidgetTester tester) =>
    tester.getRect(find.byKey(const Key('mazl-nav-rail')));
Rect _bar(WidgetTester tester) =>
    tester.getRect(find.byKey(const Key('mazl-nav-bar')));

/// Everything the user can tap or type in, wherever it is.
Iterable<Rect> _tappables(WidgetTester tester) => find
    .byWidgetPredicate(
      (w) =>
          w is InkResponse ||
          w is InkWell ||
          w is ButtonStyleButton ||
          w is EditableText,
    )
    .hitTestable()
    .evaluate()
    .map((e) {
      final box = e.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    });

void main() {
  setUpAll(loadAppFonts);
  setUp(DetailKeys.reset);

  group('breakpoint', () {
    test('compact below 600, regular from 600, whatever the device', () {
      expect(windowSizeClassForWidth(390), WindowSizeClass.compact);
      expect(
        windowSizeClassForWidth(466),
        WindowSizeClass.compact,
        reason: 'outer display',
      );
      expect(windowSizeClassForWidth(599.9), WindowSizeClass.compact);
      expect(
        windowSizeClassForWidth(kRegularMinWidth),
        WindowSizeClass.regular,
      );
      expect(
        windowSizeClassForWidth(669),
        WindowSizeClass.regular,
        reason: 'inner display',
      );
      expect(
        windowSizeClassForWidth(334),
        WindowSizeClass.compact,
        reason: 'half of the inner display in Split View',
      );
    });
  });

  group('detail targets', () {
    test('the URL says which detail is open', () {
      expect(
        DetailTarget.fromUri(Uri.parse('/chat/40')),
        const ChatDetail('40'),
      );
      expect(
        DetailTarget.fromUri(Uri.parse('/matches/profile/7')),
        const MatchProfileDetail('7'),
      );
      expect(DetailTarget.fromUri(Uri.parse('/chat')), isNull);
      expect(DetailTarget.fromUri(Uri.parse('/chat/40/video-call')), isNull);
      expect(DetailTarget.fromUri(Uri.parse('/discover/profile/7')), isNull);
    });
  });

  group('navigation frame', () {
    testWidgets('compact: the capsule floats at the bottom, no rail', (
      tester,
    ) async {
      await _Harness().pump(tester);

      expect(find.byKey(const Key('mazl-nav-bar')), findsOneWidget);
      expect(find.byKey(const Key('mazl-nav-rail')), findsNothing);
      expect(
        _compact.height - _bar(tester).bottom,
        greaterThanOrEqualTo(MazlNavBar.gap),
      );
      expect(_bar(tester).left, MazlNavBar.sideMargin);
    });

    testWidgets(
      'regular: a vertical capsule on the leading side, no bottom bar',
      (tester) async {
        await _Harness().pump(tester, size: _regular);

        expect(find.byKey(const Key('mazl-nav-bar')), findsNothing);
        final rail = _rail(tester);
        expect(rail.left, greaterThanOrEqualTo(MazlNavBar.gap));
        expect(rail.width, MazlNavBar.barHeight);
        expect(rail.top, greaterThanOrEqualTo(MazlNavBar.gap));
        expect(
          _regular.height - rail.bottom,
          greaterThanOrEqualTo(MazlNavBar.gap),
        );
      },
    );

    for (final size in [_compact, _regular]) {
      testWidgets(
        '${size.width.toInt()} pt: the same five destinations, the current one selected',
        (tester) async {
          final semantics = tester.ensureSemantics();
          await _Harness().pump(tester, size: size, initial: '/chat');

          for (final label in _tabLabels) {
            expect(find.semantics.byLabel(label), findsOne, reason: label);
          }
          expect(
            find.semantics.byLabel('Messages').evaluate().single,
            isSemantics(isSelected: true),
          );
          expect(
            find.semantics.byLabel('Profil').evaluate().single,
            isNot(isSemantics(isSelected: true)),
          );
          semantics.dispose();
        },
      );
    }

    testWidgets('regular: a tap on the rail changes tab, and the rail stays', (
      tester,
    ) async {
      await _Harness().pump(tester, size: _regular);
      await tester.tap(_railIcon(LucideIcons.user));
      await tester.pumpAndSettle();

      expect(find.text('page profile'), findsOneWidget);
      expect(find.byKey(const Key('mazl-nav-rail')), findsOneWidget);
    });

    testWidgets(
      'a single-column tab is centered in a readable column on a wide window',
      (tester) async {
        await _Harness().pump(
          tester,
          size: const Size(800, 1000),
          initial: '/profile',
        );

        final page = tester.getRect(find.byType(Scaffold).last);
        expect(page.width, kContentMaxWidth);
        final region = (
          left: _rail(tester).right + MazlNavBar.gap,
          right: 800.0,
        );
        expect(page.center.dx, closeTo((region.left + region.right) / 2, 1));
      },
    );

    testWidgets(
      'a window wide enough for two pages gives a tab the whole room',
      (tester) async {
        await _Harness().pump(
          tester,
          size: const Size(1000, 900),
          initial: '/profile',
        );

        final page = tester.getRect(find.byType(Scaffold).last);
        final region = (
          left: _rail(tester).right + MazlNavBar.gap,
          right: 1000.0,
        );
        expect(page.width, closeTo(region.right - region.left, 1));
      },
    );

    testWidgets(
      'on the inner display itself the column is the whole room left by the rail',
      (tester) async {
        await _Harness().pump(tester, size: _regular, initial: '/profile');

        final page = tester.getRect(find.byType(Scaffold).last);
        final region = _regular.width - _rail(tester).right - MazlNavBar.gap;
        expect(
          page.width,
          region < kContentMaxWidth ? region : kContentMaxWidth,
        );
      },
    );
  });

  group('safe areas', () {
    // System controls along ONE edge: right 60, left 0.
    const asymmetric = FakeViewPadding(right: 60, top: 20, bottom: 34);

    for (final size in [_compact, _regular]) {
      for (final open in ['/discover', '/chat']) {
        testWidgets(
          '${size.width.toInt()} pt, right inset 60, $open: nothing tappable enters the unsafe area',
          (tester) async {
            await _Harness().pump(
              tester,
              size: size,
              padding: asymmetric,
              initial: open,
            );
            if (open == '/chat') {
              await tester.tap(find.text('Noémie'));
              await tester.pumpAndSettle();
            }

            final rects = _tappables(tester).toList();
            expect(rects, isNotEmpty);
            expect(
              rects.map((r) => r.right).reduce((a, b) => a > b ? a : b),
              greaterThan(size.width - 60 - 100),
              reason:
                  'something is drawn near the unsafe edge, so the check means something',
            );
            for (final rect in rects) {
              expect(
                rect.right,
                lessThanOrEqualTo(size.width - 60 + 0.01),
                reason: '$rect',
              );
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(
                rect.bottom,
                lessThanOrEqualTo(size.height - 34 + 0.01),
                reason: '$rect',
              );
            }
          },
        );
      }
    }

    testWidgets('regular, left inset 40: the rail clears it by the usual gap', (
      tester,
    ) async {
      await _Harness().pump(
        tester,
        size: _regular,
        padding: const FakeViewPadding(left: 40, bottom: 34),
      );
      expect(_rail(tester).left, 40 + MazlNavBar.gap);
    });

    testWidgets('compact, left inset 40: the capsule clears it too', (
      tester,
    ) async {
      await _Harness().pump(
        tester,
        padding: const FakeViewPadding(left: 40, bottom: 34),
      );
      expect(_bar(tester).left, 40 + MazlNavBar.sideMargin);
    });
  });

  group('messages: list | conversation', () {
    testWidgets('regular: the list and an invitation to pick a conversation', (
      tester,
    ) async {
      await _Harness().pump(tester, size: _regular, initial: '/chat');

      expect(find.text('page chat'), findsOneWidget);
      expect(find.text('Choisissez une conversation'), findsOneWidget);
      final list = tester.getRect(find.text('page chat'));
      final invitation = tester.getRect(
        find.text('Choisissez une conversation'),
      );
      expect(
        list.center.dx,
        lessThan(invitation.center.dx),
        reason: 'list first, detail after, in reading order',
      );
    });

    testWidgets(
      'regular: opening a conversation shows it NEXT to the list, not over it',
      (tester) async {
        await _Harness().pump(tester, size: _regular, initial: '/chat');
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();

        expect(find.byType(ChatConversationScreen), findsOneWidget);
        expect(
          find.text('page chat'),
          findsOneWidget,
          reason: 'the list is still there',
        );
        expect(find.text('Choisissez une conversation'), findsNothing);
        final chat = tester.getRect(find.byType(ChatConversationScreen));
        final list = tester.getRect(find.text('page chat'));
        expect(chat.left, greaterThan(list.right - 1));
        // The rail is still reachable.
        expect(find.byKey(const Key('mazl-nav-rail')), findsOneWidget);
      },
    );

    testWidgets(
      'compact: opening a conversation is the full-screen push it always was',
      (tester) async {
        await _Harness().pump(tester, initial: '/chat');
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();

        final chat = tester.getRect(find.byType(ChatConversationScreen));
        expect(chat.size, _compact);
        expect(find.text('Choisissez une conversation'), findsNothing);
      },
    );

    testWidgets(
      'the open conversation survives 390 -> 700 -> 390, draft included',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, initial: '/chat');
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Je suis en retard');
        await tester.pump();
        final composer = tester.state<EditableTextState>(
          find.byType(EditableText),
        );

        // Unfold: the same conversation moves into the pane.
        await _resize(tester, _regular);
        expect(
          h.router.routerDelegate.currentConfiguration.uri.path,
          '/chat/$conversationId',
        );
        expect(find.byType(ChatConversationScreen), findsOneWidget);
        expect(find.text('page chat'), findsOneWidget);
        expect(
          find.text('Je suis en retard'),
          findsOneWidget,
          reason: 'the half-typed message is kept',
        );
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(composer),
          reason: 'same screen, moved',
        );
        expect(find.byKey(const Key('mazl-nav-rail')), findsOneWidget);

        // Fold again: full screen once more, still the same conversation.
        await _resize(tester, _compact);
        expect(find.byType(ChatConversationScreen), findsOneWidget);
        expect(
          tester.getRect(find.byType(ChatConversationScreen)).size,
          _compact,
        );
        expect(find.text('Je suis en retard'), findsOneWidget);
        expect(find.byKey(const Key('mazl-nav-bar')), findsOneWidget);
        expect(
          h.router.routerDelegate.currentConfiguration.uri.path,
          '/chat/$conversationId',
        );
      },
    );

    testWidgets('regular: typing in the pane works under the empty route', (
      tester,
    ) async {
      await _Harness().pump(tester, size: _regular, initial: '/chat');
      await tester.tap(find.text('Noémie'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Bonjour');
      await tester.pump();
      expect(find.text('Bonjour'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNotNull,
        reason: 'the composer owns the focus',
      );
    });

    testWidgets(
      'regular: back closes the conversation and brings the invitation back',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, size: _regular, initial: '/chat');
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();

        h.router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(ChatConversationScreen), findsNothing);
        expect(find.text('Choisissez une conversation'), findsOneWidget);
        expect(h.router.routerDelegate.currentConfiguration.uri.path, '/chat');
      },
    );

    testWidgets(
      'regular: the empty route does not block the rail or the list',
      (tester) async {
        await _Harness().pump(tester, size: _regular, initial: '/chat');
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('count-chat')));
        await tester.pump();
        expect(
          find.text('n1'),
          findsOneWidget,
          reason: 'the list answers to touches',
        );
        await tester.tap(_railIcon(LucideIcons.user));
        await tester.pumpAndSettle();
        expect(find.text('page profile'), findsOneWidget);
      },
    );

    testWidgets(
      'compact: the shell below a conversation is hidden from touches and VoiceOver',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _Harness().pump(tester, initial: '/chat');
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();

        expect(find.semantics.byLabel('Profil'), findsNothing);
        semantics.dispose();
      },
    );
  });

  group('matches: list | profile', () {
    testWidgets(
      'regular: the profile opens next to the list and closes from it',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, size: _regular, initial: '/matches');
        expect(find.text('Choisissez un match'), findsOneWidget);

        await tester.tap(find.text('Voir le profil 7'));
        await tester.pumpAndSettle();
        expect(find.text('profil 7'), findsOneWidget);
        expect(find.text('page matches'), findsOneWidget);
        expect(find.text('Choisissez un match'), findsNothing);

        await tester.tap(find.text('fermer'));
        await tester.pumpAndSettle();
        expect(find.text('profil 7'), findsNothing);
        expect(find.text('Choisissez un match'), findsOneWidget);
      },
    );

    testWidgets('the open profile survives 700 -> 390 -> 700', (tester) async {
      await _Harness().pump(tester, size: _regular, initial: '/matches');
      await tester.tap(find.text('Voir le profil 7'));
      await tester.pumpAndSettle();

      await _resize(tester, _compact);
      expect(find.text('profil 7'), findsOneWidget);
      expect(tester.getRect(find.byType(Scaffold).last).size, _compact);

      await _resize(tester, _regular);
      expect(find.text('profil 7'), findsOneWidget);
      expect(find.text('page matches'), findsOneWidget);
    });
  });

  group('folding keeps the rest too', () {
    testWidgets('the tab state survives the change of frame', (tester) async {
      await _Harness().pump(tester, initial: '/discover');
      await tester.tap(find.byKey(const Key('count-discover')));
      await tester.pump();
      expect(find.text('n1'), findsOneWidget);

      await _resize(tester, _regular);
      expect(find.text('n1'), findsOneWidget);
      await _resize(tester, _compact);
      expect(find.text('n1'), findsOneWidget);
    });

    testWidgets(
      'switching between a two-pane tab and a single-column tab keeps both alive',
      (tester) async {
        await _Harness().pump(tester, size: _regular, initial: '/discover');
        await tester.tap(find.byKey(const Key('count-discover')));
        await tester.pump();

        await tester.tap(_railIcon(LucideIcons.messageCircle));
        await tester.pumpAndSettle();
        expect(find.text('Choisissez une conversation'), findsOneWidget);
        await tester.tap(_railIcon(LucideIcons.layers));
        await tester.pumpAndSettle();
        expect(find.text('n1'), findsOneWidget);
        expect(find.text('Choisissez une conversation'), findsNothing);
      },
    );
  });

  group('sheets', () {
    Future<double> sheetWidth(WidgetTester tester, Size size) async {
      await _Harness().pump(tester, size: size, initial: '/profile');
      showMazlSheet<void>(
        tester.element(find.text('page profile')),
        builder: (_) => const SizedBox(
          width: double.infinity,
          height: 80,
          child: Text('contenu'),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .getSize(
            find
                .descendant(
                  of: find.byType(BottomSheet),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width;
    }

    testWidgets('compact: as wide as the window', (tester) async {
      expect(await sheetWidth(tester, _compact), _compact.width);
    });

    testWidgets('wide window: no wider than a page column', (tester) async {
      expect(await sheetWidth(tester, const Size(900, 900)), kContentMaxWidth);
    });
  });

  group('right to left (Hebrew)', () {
    const he = Locale('he');

    testWidgets(
      'regular: the rail is on the right, the list on the right and the detail on its left',
      (tester) async {
        await _Harness().pump(
          tester,
          size: _regular,
          locale: he,
          initial: '/chat',
        );

        final rail = _rail(tester);
        expect(
          _regular.width - rail.right,
          greaterThanOrEqualTo(MazlNavBar.gap),
        );
        expect(rail.center.dx, greaterThan(_regular.width / 2));
        final list = tester.getRect(find.text('page chat'));
        final invitation = tester.getRect(find.text('לבחור שיחה'));
        expect(
          list.center.dx,
          greaterThan(invitation.center.dx),
          reason: 'start -> end is right -> left',
        );
        expect(list.center.dx, lessThan(rail.left));
      },
    );

    testWidgets(
      'regular: an open conversation appears on the left of the list',
      (tester) async {
        await _Harness().pump(
          tester,
          size: _regular,
          locale: he,
          initial: '/chat',
        );
        await tester.tap(find.text('Noémie'));
        await tester.pumpAndSettle();

        final chat = tester.getRect(find.byType(ChatConversationScreen));
        final list = tester.getRect(find.text('page chat'));
        expect(chat.right, lessThanOrEqualTo(list.left + 1));
      },
    );

    testWidgets(
      'compact: the capsule is still at the bottom, starting on the right',
      (tester) async {
        await _Harness().pump(tester, locale: he);
        expect(_compact.width - _bar(tester).right, MazlNavBar.sideMargin);
      },
    );

    testWidgets(
      'left inset 60 (the end side in Hebrew): content stays out of it, the rail is not pushed',
      (tester) async {
        const inset = FakeViewPadding(left: 60, bottom: 34);
        await _Harness().pump(
          tester,
          size: _regular,
          locale: he,
          padding: inset,
          initial: '/chat',
        );

        expect(_regular.width - _rail(tester).right, MazlNavBar.gap);
        for (final rect in _tappables(tester)) {
          expect(rect.left, greaterThanOrEqualTo(60 - 0.01), reason: '$rect');
        }
      },
    );

    testWidgets(
      'right inset 60 (the start side in Hebrew): the rail clears it',
      (tester) async {
        await _Harness().pump(
          tester,
          size: _regular,
          locale: he,
          padding: const FakeViewPadding(right: 60, bottom: 34),
          initial: '/chat',
        );
        expect(_regular.width - _rail(tester).right, 60 + MazlNavBar.gap);
      },
    );
  });
}
