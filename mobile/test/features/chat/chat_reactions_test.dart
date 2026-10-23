import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/chat/screens/chat_conversation_screen.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';

import 'chat_test_support.dart';

// docs/design/CHAT.md §4, §5 and §14: the reactions at WhatsApp / iMessage
// level: veil, bar on the bubble side, press-drag-release, pill, heart.

const _barKey = ValueKey('reaction-bar');
const _menuKey = ValueKey('message-menu');
const _pillKey = ValueKey('reaction-pill');
const _fillKey = ValueKey('reaction-pill-fill');
const _discKey = ValueKey('reaction-disc');
const _veilKey = ValueKey('overlay-veil');

const _heart = '❤️';
const _laugh = '😂';
const _wow = '😮';

/// Records the haptics the app asks for ('HapticFeedbackType.lightImpact'…).
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

Finder _inBar(Finder matching) =>
    find.descendant(of: find.byKey(_barKey), matching: matching);

/// Presses the bubble and keeps the finger down until the overlay is up and
/// its bar has finished growing.
Future<TestGesture> _pressAndHold(WidgetTester tester, ChatMessage m) async {
  final gesture = await tester.startGesture(tester.getCenter(bubbleOf(m)));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 600));
  return gesture;
}

ColorScheme _scheme(WidgetTester tester, Finder from) =>
    Theme.of(tester.element(from.first)).colorScheme;

/// Painted size, transforms included (getSize is the layout size).
Size _size(WidgetTester tester, Finder f) => tester.getRect(f).size;

Color _decorationColor(WidgetTester tester, Finder finder) =>
    (tester.widget<Container>(finder).decoration! as BoxDecoration).color!;

void main() {
  setUpAll(loadChatFonts);

  group('veil', () {
    testWidgets('a background blur sits under the lifted bubble', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      final blur = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(blur.filter.toString(), contains('16'));
    });

    testWidgets('no blur at all when animations are disabled', (tester) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(
        initial: chatState([m]),
      ).pump(tester, disableAnimations: true);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      expect(find.byKey(_barKey), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    for (final (brightness, alpha) in [
      (Brightness.light, 0.2),
      (Brightness.dark, 0.4),
    ]) {
      testWidgets('the black veil is ${alpha * 100} % in $brightness', (
        tester,
      ) async {
        final m = msg(5, other, 'Salut', at: today(10, 0));
        await ChatHarness(
          initial: chatState([m]),
        ).pump(tester, brightness: brightness);
        await tester.longPress(bubbleOf(m));
        await tester.pumpAndSettle();
        final veil = tester.widget<ColoredBox>(find.byKey(_veilKey));
        expect(veil.color.a, closeTo(alpha, 0.01));
        expect(veil.color.r, 0);
      });
    }

    testWidgets('without animations the veil is 40 % even in light', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(
        initial: chatState([m]),
      ).pump(tester, disableAnimations: true);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      final veil = tester.widget<ColoredBox>(find.byKey(_veilKey));
      expect(veil.color.a, closeTo(0.4, 0.01));
    });
  });

  group('menu lifetime', () {
    testWidgets('the back button closes the menu first, not the screen', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      expect(find.byKey(_barKey), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(_barKey), findsNothing);
      expect(find.byKey(_menuKey), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ChatConversationScreen), findsOneWidget);
    });
  });

  group('reaction bar', () {
    testWidgets('44 px capsule: six 40 px slots, 2 px apart, 6 px padding', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byKey(_barKey));
      expect(bar.height, 44);
      expect(bar.width, 6 * 40 + 5 * 2 + 12 + 2);
      final first = tester.getCenter(_inBar(find.text(_heart)));
      final second = tester.getCenter(_inBar(find.text(_laugh)));
      expect(second.dx - first.dx, 42);
      expect(first.dx - bar.left, 1 + 6 + 20);
      expect(
        tester.widget<Text>(_inBar(find.text(_heart))).style!.fontSize,
        28,
      );
    });

    testWidgets('a received message: the bar starts at the bubble left edge', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      final bubble = tester.getRect(bubbleOf(m));
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byKey(_barKey));
      expect(bar.left, closeTo(bubble.left, 0.5));
    });

    testWidgets('my message: the bar ends at the bubble right edge', (
      tester,
    ) async {
      final m = msg(5, me, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      final bubble = tester.getRect(bubbleOf(m));
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byKey(_barKey));
      expect(bar.right, closeTo(bubble.right, 0.5));
    });

    testWidgets('it grows from the bubble corner and the emojis pop in turn', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      await tester.longPress(bubbleOf(m));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final growing = tester.getRect(find.byKey(_barKey));
      final heartEarly = _size(tester, _inBar(find.text(_heart)));
      final wowEarly = _size(tester, _inBar(find.text(_wow)));
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byKey(_barKey));
      expect(growing.width, lessThan(settled.width));
      // Anchored on the bubble-side bottom corner.
      expect(growing.left, closeTo(settled.left, 0.5));
      expect(growing.bottom, closeTo(settled.bottom, 0.5));
      // The first emoji is further along than the third.
      expect(heartEarly.width, greaterThan(wowEarly.width));
      expect(
        _size(tester, _inBar(find.text(_wow))).width,
        greaterThan(wowEarly.width),
      );
    });

    testWidgets('without animations the bar is there at once, full size', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(
        initial: chatState([m]),
      ).pump(tester, disableAnimations: true);
      await tester.longPress(bubbleOf(m));
      await tester.pump();
      expect(tester.getRect(find.byKey(_barKey)).width, 264);
      expect(_size(tester, _inBar(find.text(_wow))).width, greaterThan(0));
    });

    testWidgets('my reaction has a filled disc, no accent; others have none', (
      tester,
    ) async {
      final m = msg(
        5,
        other,
        'Salut',
        at: today(10, 0),
        reactions: const [
          Reaction(emoji: _laugh, userIds: [me]),
          Reaction(emoji: _wow, userIds: [other]),
        ],
      );
      await ChatHarness(initial: chatState([m])).pump(tester);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      final disc = _inBar(find.byKey(_discKey));
      expect(disc, findsOneWidget);
      expect(
        _decorationColor(tester, disc),
        _scheme(tester, disc).surfaceContainerHighest,
      );
      expect(
        tester.getCenter(disc).dx,
        closeTo(tester.getCenter(_inBar(find.text(_laugh))).dx, 0.5),
      );
    });

    testWidgets('tapping my reaction again toggles it', (tester) async {
      final m = msg(
        5,
        other,
        'Salut',
        at: today(10, 0),
        reactions: const [
          Reaction(emoji: _laugh, userIds: [me]),
        ],
      );
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      await tester.longPress(bubbleOf(m));
      await tester.pumpAndSettle();
      await tester.tap(_inBar(find.text(_laugh)));
      await tester.pumpAndSettle();
      expect(harness.actions.reactions, [(messageId: 5, emoji: _laugh)]);
    });
  });

  group('press, drag, release', () {
    testWidgets('releasing over an emoji reacts with it and closes the menu', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      final finger = await _pressAndHold(tester, m);
      expect(find.byKey(_barKey), findsOneWidget);

      await finger.moveTo(tester.getCenter(_inBar(find.text(_laugh))));
      await tester.pump(const Duration(milliseconds: 200));
      await finger.up();
      await tester.pumpAndSettle();

      expect(harness.actions.reactions, [(messageId: 5, emoji: _laugh)]);
      expect(find.byKey(_barKey), findsNothing);
      expect(find.byKey(_menuKey), findsNothing);
    });

    testWidgets('the emoji under the finger grows to 1.35 and rises 8 px', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      final finger = await _pressAndHold(tester, m);
      final restSize = _size(tester, _inBar(find.text(_laugh)));
      final restCentre = tester.getCenter(_inBar(find.text(_laugh)));

      await finger.moveTo(restCentre);
      await tester.pump(); // builds and starts the 120 ms animation
      await tester.pump(const Duration(milliseconds: 200));
      final size = _size(tester, _inBar(find.text(_laugh)));
      final centre = tester.getCenter(_inBar(find.text(_laugh)));
      expect(size.width / restSize.width, closeTo(1.35, 0.01));
      expect(restCentre.dy - centre.dy, closeTo(8, 0.5));
      // The neighbour stays put.
      expect(_size(tester, _inBar(find.text(_wow))), restSize);

      await finger.moveTo(const Offset(20, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_size(tester, _inBar(find.text(_laugh))), restSize);
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a selection click on each change of hovered emoji', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      final m = msg(5, other, 'Salut', at: today(10, 0));
      await ChatHarness(initial: chatState([m])).pump(tester);
      final finger = await _pressAndHold(tester, m);
      haptics.clear();

      await finger.moveTo(tester.getCenter(_inBar(find.text(_laugh))));
      await tester.pump();
      await finger.moveBy(const Offset(2, 0));
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.selectionClick']);

      await finger.moveTo(tester.getCenter(_inBar(find.text(_wow))));
      await tester.pump();
      expect(haptics, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('releasing elsewhere leaves the bar and the menu open', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      final finger = await _pressAndHold(tester, m);

      await finger.moveTo(tester.getCenter(_inBar(find.text(_laugh))));
      await tester.pump(const Duration(milliseconds: 200));
      await finger.moveTo(const Offset(20, 10));
      await tester.pump(const Duration(milliseconds: 200));
      await finger.up();
      await tester.pumpAndSettle();

      expect(harness.actions.reactions, isEmpty);
      expect(find.byKey(_barKey), findsOneWidget);
      expect(find.byKey(_menuKey), findsOneWidget);
    });

    testWidgets('lifting the finger without moving reacts to nothing', (
      tester,
    ) async {
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      final finger = await _pressAndHold(tester, m);
      await finger.up();
      await tester.pumpAndSettle();
      expect(harness.actions.reactions, isEmpty);
      expect(find.byKey(_barKey), findsOneWidget);
    });
  });

  group('reaction pill', () {
    ChatMessage withReactions(List<Reaction> reactions, {int sender = me}) =>
        msg(5, sender, 'Salut', at: today(10, 0), reactions: reactions);

    testWidgets('24 px high, no outline, a 2 px ring in the page colour', (
      tester,
    ) async {
      final m = withReactions(const [
        Reaction(emoji: _heart, userIds: [other]),
      ]);
      await ChatHarness(initial: chatState([m])).pump(tester);
      final pill = tester.getRect(find.byKey(_pillKey));
      final fill = tester.getRect(find.byKey(_fillKey));
      expect(fill.height, 24);
      expect(pill.height, 28);
      expect(pill.bottom - fill.bottom, 2);
      final ring = tester.widget<Container>(find.byKey(_pillKey));
      final fillBox = tester.widget<Container>(find.byKey(_fillKey));
      expect(
        (ring.decoration! as BoxDecoration).color,
        Theme.of(tester.element(find.byKey(_pillKey))).scaffoldBackgroundColor,
      );
      expect((ring.decoration! as BoxDecoration).border, isNull);
      expect((fillBox.decoration! as BoxDecoration).border, isNull);
      expect(tester.widget<Text>(find.text(_heart)).style!.fontSize, 15);
    });

    testWidgets('it bites 8 px into the bubble', (tester) async {
      final m = withReactions(const [
        Reaction(emoji: _heart, userIds: [other]),
      ]);
      await ChatHarness(initial: chatState([m])).pump(tester);
      expect(
        tester.getRect(bubbleOf(m)).bottom -
            tester.getRect(find.byKey(_pillKey)).top,
        8,
      );
    });

    testWidgets('surface when I did not react, primary at 12 % when I did', (
      tester,
    ) async {
      final theirs = withReactions(const [
        Reaction(emoji: _heart, userIds: [other]),
      ]);
      final harness = ChatHarness(initial: chatState([theirs]));
      await harness.pump(tester);
      final scheme = _scheme(tester, find.byKey(_fillKey));
      expect(_decorationColor(tester, find.byKey(_fillKey)), scheme.surface);

      harness.setState(
        chatState([
          withReactions(const [
            Reaction(emoji: _heart, userIds: [other, me]),
          ]),
        ]),
      );
      await tester.pumpAndSettle();
      expect(
        _decorationColor(tester, find.byKey(_fillKey)),
        Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.12),
          scheme.surface,
        ),
      );
    });

    testWidgets('three distinct emojis at most, most users first, then total', (
      tester,
    ) async {
      final m = withReactions(const [
        Reaction(emoji: _heart, userIds: [other]),
        Reaction(emoji: _laugh, userIds: [other, me]),
        Reaction(emoji: _wow, userIds: [other]),
        Reaction(emoji: '😢', userIds: [other]),
      ]);
      await ChatHarness(initial: chatState([m])).pump(tester);
      expect(find.text('😢'), findsNothing);
      expect(find.text('5'), findsOneWidget);
      final laugh = tester.getCenter(find.text(_laugh)).dx;
      final heart = tester.getCenter(find.text(_heart)).dx;
      final wow = tester.getCenter(find.text(_wow)).dx;
      final total = tester.getCenter(find.text('5')).dx;
      expect(laugh, lessThan(heart));
      expect(heart, lessThan(wow));
      expect(wow, lessThan(total));
      final style = tester.widget<Text>(find.text('5')).style!;
      expect(style.fontSize, 12);
      expect(style.color, _scheme(tester, find.text('5')).onSurfaceVariant);
    });

    testWidgets('a single reaction shows no count', (tester) async {
      final m = withReactions(const [
        Reaction(emoji: _heart, userIds: [other]),
      ]);
      await ChatHarness(initial: chatState([m])).pump(tester);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('a reaction arriving makes the pill pop', (tester) async {
      final plain = msg(5, me, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([plain]));
      await harness.pump(tester);
      expect(find.byKey(_pillKey), findsNothing);

      harness.setState(
        chatState([
          withReactions(const [
            Reaction(emoji: _heart, userIds: [other]),
          ]),
        ]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final early = _size(tester, find.byKey(_pillKey));
      await tester.pumpAndSettle();
      final settled = _size(tester, find.byKey(_pillKey));
      expect(early.width, lessThan(settled.width));

      // Its content changing pops it again.
      harness.setState(
        chatState([
          withReactions(const [
            Reaction(emoji: _heart, userIds: [other]),
            Reaction(emoji: _laugh, userIds: [other]),
          ]),
        ]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        _size(tester, find.byKey(_pillKey)).height,
        lessThan(settled.height),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('no pop when animations are disabled', (tester) async {
      final plain = msg(5, me, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([plain]));
      await harness.pump(tester, disableAnimations: true);
      harness.setState(
        chatState([
          withReactions(const [
            Reaction(emoji: _heart, userIds: [other]),
          ]),
        ]),
      );
      await tester.pump();
      final first = _size(tester, find.byKey(_pillKey));
      await tester.pumpAndSettle();
      expect(_size(tester, find.byKey(_pillKey)), first);
    });
  });

  group('double tap heart', () {
    testWidgets('a 64 px heart bursts at the tap point, with a light impact', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      final m = msg(5, other, 'Salut', at: today(10, 0));
      final harness = ChatHarness(initial: chatState([m]));
      await harness.pump(tester);
      final point = tester.getTopLeft(bubbleOf(m)) + const Offset(31, 9);

      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 100));

      expect(harness.actions.reactions, [(messageId: 5, emoji: _heart)]);
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      final pop = find.byKey(const ValueKey('heart-pop'));
      expect(pop, findsOneWidget);
      expect((tester.getCenter(pop) - point).distance, lessThan(3));
      expect(
        tester
            .widget<Text>(find.descendant(of: pop, matching: find.byType(Text)))
            .style!
            .fontSize,
        64,
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(pop, findsNothing);
    });

    testWidgets(
      'the burst follows the finger: another tap point, another spot',
      (tester) async {
        final m = msg(5, other, 'Salut', at: today(10, 0));
        await ChatHarness(initial: chatState([m])).pump(tester);
        final point = tester.getTopRight(bubbleOf(m)) + const Offset(-20, 12);
        await tester.tapAt(point);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(point);
        await tester.pump(const Duration(milliseconds: 100));
        final pop = find.byKey(const ValueKey('heart-pop'));
        expect((tester.getCenter(pop) - point).distance, lessThan(3));
        await tester.pumpAndSettle();
      },
    );
  });
}
