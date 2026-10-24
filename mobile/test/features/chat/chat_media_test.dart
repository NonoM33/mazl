import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/widgets/chat_image.dart';
import 'package:mazl/presentation/features/chat/widgets/photo_grid.dart';
import 'package:mazl/presentation/features/chat/widgets/photo_viewer.dart';
import 'package:mazl/presentation/features/chat/widgets/voice_bubble.dart';
import 'package:mazl/presentation/features/chat/widgets/waveform.dart';

import 'chat_test_support.dart';

List<ChatMedia> _photos(int n, {int? width, int? height}) => [
  for (var i = 0; i < n; i++)
    ChatMedia(id: i + 1, url: tinyPngUri, width: width, height: height),
];

ChatMessage _photoMessage(
  int id,
  int sender,
  int count, {
  int? width,
  int? height,
  String caption = '',
  DateTime? at,
}) => msg(
  id,
  sender,
  caption,
  type: ChatMessageType.photo,
  media: _photos(count, width: width, height: height),
  at: at,
);

Finder get _blur => find.byType(ImageFiltered);

void main() {
  setUpAll(loadChatFonts);

  group('photo layouts', () {
    testWidgets(
      'one photo: 220 wide at its own ratio (bounded 160-300), the bubble is the photo',
      (tester) async {
        final portrait = _photoMessage(1, me, 1, width: 600, height: 800);
        final panorama = _photoMessage(
          2,
          me,
          1,
          width: 1600,
          height: 400,
          at: today(11, 0),
        );
        final tall = _photoMessage(
          3,
          me,
          1,
          width: 300,
          height: 1200,
          at: today(12, 0),
        );
        await ChatHarness(
          initial: chatState([portrait, panorama, tall]),
        ).pump(tester);
        expect(
          tester.getSize(bubbleOf(portrait)),
          Size(220, (220 * 800 / 600).clamp(160, 300).toDouble()),
        );
        expect(tester.getSize(bubbleOf(panorama)).height, 160);
        expect(tester.getSize(bubbleOf(tall)).height, 300);
      },
    );

    testWidgets('two photos side by side, 2 px apart', (tester) async {
      final m = _photoMessage(1, me, 2);
      await ChatHarness(initial: chatState([m])).pump(tester);
      final cells = tester.widgetList<Hero>(find.byType(Hero)).length;
      expect(cells, 2);
      final a = tester.getRect(
        find.byWidgetPredicate((w) => w is Hero && w.tag == 'photo-c-1-0'),
      );
      final b = tester.getRect(
        find.byWidgetPredicate((w) => w is Hero && w.tag == 'photo-c-1-1'),
      );
      expect(b.left - a.right, 2);
      expect(a.top, b.top);
    });

    // Review 2026-10-24: the 2 px gap showed the sent bubble's blue. CHAT.md:
    // « la bulle EST la photo » — the gap shows the page.
    testWidgets('the gap between photos shows the page, not the bubble colour', (tester) async {
      final m = _photoMessage(1, me, 2);
      await ChatHarness(initial: chatState([m])).pump(tester);
      final grid = find.byType(PhotoGrid);
      final page = Theme.of(tester.element(grid)).colorScheme.surface;
      final backing = find.descendant(
        of: grid,
        matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == page),
      );
      expect(backing, findsOneWidget);
      final a = tester.getRect(find.byWidgetPredicate((w) => w is Hero && w.tag == 'photo-c-1-0'));
      final b = tester.getRect(find.byWidgetPredicate((w) => w is Hero && w.tag == 'photo-c-1-1'));
      final back = tester.getRect(backing);
      expect(back.left <= a.left && back.right >= b.right && back.top <= a.top && back.bottom >= a.bottom, isTrue);
    });

    testWidgets('three photos: one wide on top, two below', (tester) async {
      final m = _photoMessage(1, me, 3);
      await ChatHarness(initial: chatState([m])).pump(tester);
      Rect cell(int i) => tester.getRect(
        find.byWidgetPredicate((w) => w is Hero && w.tag == 'photo-c-1-$i'),
      );
      expect(cell(0).width, 220);
      expect(cell(1).top, cell(0).bottom + 2);
      expect(cell(1).top, cell(2).top);
    });

    testWidgets('four photos: a 2x2 grid with no counter', (tester) async {
      await ChatHarness(
        initial: chatState([_photoMessage(1, me, 4)]),
      ).pump(tester);
      expect(find.byType(Hero), findsNWidgets(4));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('seven photos: at most four cells, « +3 » on the fourth', (
      tester,
    ) async {
      await ChatHarness(
        initial: chatState([_photoMessage(1, me, 7)]),
      ).pump(tester);
      expect(find.byType(Hero), findsNWidgets(4));
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('a caption sits under the photo, inside the bubble', (
      tester,
    ) async {
      final m = _photoMessage(1, me, 1, caption: 'Vue de ma terrasse');
      await ChatHarness(initial: chatState([m])).pump(tester);
      final bubble = tester.getRect(bubbleOf(m));
      expect(
        tester.getRect(find.text('Vue de ma terrasse')).bottom,
        lessThanOrEqualTo(bubble.bottom),
      );
    });
  });

  group('received photos', () {
    testWidgets(
      'arrive blurred with « Voir la photo »; the first tap uncovers, the second opens the viewer',
      (tester) async {
        final m = _photoMessage(1, other, 1);
        await ChatHarness(initial: chatState([m])).pump(tester);
        expect(_blur, findsOneWidget);
        expect(find.text('Voir la photo'), findsOneWidget);
        final blur = tester.widget<ImageFiltered>(_blur);
        expect(
          blur.imageFilter,
          ui.ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
            tileMode: TileMode.mirror,
          ),
        );

        await tester.tap(find.text('Voir la photo'));
        await tester.pump();
        expect(_blur, findsNothing);
        expect(find.text('Voir la photo'), findsNothing);
        expect(
          find.byType(PhotoViewer),
          findsNothing,
          reason: 'the first tap only uncovers',
        );

        await tester.tap(bubbleOf(m));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PhotoViewer), findsOneWidget);
      },
    );

    testWidgets(
      'once uncovered, a photo stays uncovered while the list rebuilds',
      (tester) async {
        final m = _photoMessage(1, other, 1);
        final harness = ChatHarness(initial: chatState([m]));
        await harness.pump(tester);
        await tester.tap(find.text('Voir la photo'));
        await tester.pump();
        harness.setState(
          harness.state.copyWith(
            messages: [
              m,
              msg(2, other, 'Et ça ?', at: today(10, 30)),
            ],
          ),
        );
        await tester.pump();
        expect(_blur, findsNothing);
      },
    );

    testWidgets('my own photos are never blurred', (tester) async {
      await ChatHarness(
        initial: chatState([_photoMessage(1, me, 2)]),
      ).pump(tester);
      expect(_blur, findsNothing);
    });
  });

  group('viewer', () {
    Future<ChatMessage> openViewer(WidgetTester tester, {int count = 3}) async {
      final m = _photoMessage(1, me, count);
      await ChatHarness(initial: chatState([m])).pump(tester);
      await tester.tap(
        find.byWidgetPredicate((w) => w is Hero && w.tag == 'photo-c-1-1'),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      return m;
    }

    testWidgets(
      'opens on the touched photo, black, with one white dot per photo',
      (tester) async {
        await openViewer(tester);
        expect(find.byType(PhotoViewer), findsOneWidget);
        final scaffold = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(PhotoViewer),
            matching: find.byType(Scaffold),
          ),
        );
        expect(scaffold.backgroundColor, Colors.black);
        final dots = find.descendant(
          of: find.byType(PhotoViewer),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect(dots, findsNWidgets(3));
      },
    );

    testWidgets('the cross closes it', (tester) async {
      await openViewer(tester);
      final cross = find.byTooltip('Fermer');
      expect(tester.getSize(cross), const Size(44, 44));
      await tester.tap(cross);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PhotoViewer), findsNothing);
    });

    // Regression (simulator, 2026-10-24): after closing the viewer, the
    // status bar stayed white on the white conversation (time invisible).
    testWidgets('closing it gives the conversation back its dark status bar icons', (tester) async {
      await openViewer(tester);
      await tester.pump();
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light, reason: 'viewer: light icons on black');
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark, reason: 'light theme: dark icons on white');
      expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light, reason: 'iOS: dark text on a light bar');
    });

    testWidgets('dragging down closes it', (tester) async {
      await openViewer(tester);
      await tester.fling(find.byType(PhotoViewer), const Offset(0, 400), 1500);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PhotoViewer), findsNothing);
    });

    testWidgets('swiping moves to the next photo', (tester) async {
      await openViewer(tester);
      await tester.fling(find.byType(PhotoViewer), const Offset(-300, 0), 1500);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      final lit = find.descendant(
        of: find.byType(PhotoViewer),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration! as BoxDecoration).color!.a == 1,
        ),
      );
      expect(lit, findsOneWidget);
      expect(
        tester.getCenter(lit).dx,
        greaterThan(tester.getCenter(find.byType(PhotoViewer)).dx),
      );
    });
  });

  group('images', () {
    testWidgets(
      'a photo still being sent shows its bytes before the upload ends',
      (tester) async {
        final bytes = ChatImage.decodeDataUri(tinyPngUri)!;
        final sending = ChatMessage(
          id: -1,
          clientId: 'c-local',
          conversationId: conversationId,
          senderId: me,
          type: ChatMessageType.photo,
          content: '',
          createdAt: today(10, 0),
          status: MessageStatus.sending,
          localMedia: [bytes],
        );
        await ChatHarness(initial: chatState([sending])).pump(tester);
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<MemoryImage>());
        expect((image.image as MemoryImage).bytes, bytes);
      },
    );

    testWidgets('a data: URI renders from memory', (tester) async {
      await ChatHarness(
        initial: chatState([_photoMessage(1, me, 1)]),
      ).pump(tester);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<MemoryImage>(),
      );
    });

    test('data: URIs decode, anything else is refused without throwing', () {
      expect(ChatImage.decodeDataUri(tinyPngUri), isA<Uint8List>());
      expect(ChatImage.decodeDataUri('data:not base64!!'), isNull);
    });

    testWidgets('file: and other schemes are not drawn', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatImage(url: 'file:///etc/passwd'),
        ),
      );
      expect(find.byType(Image), findsNothing);
    });
  });

  group('voice bubble', () {
    final voice = VoiceNote(
      id: 1,
      url: 'data:audio/mp4;base64,AAAA',
      durationMs: 8300,
      waveform: List.generate(48, (i) => (i * 7) % 100),
    );
    ChatMessage voiceMessage({int sender = me}) =>
        msg(1, sender, '', type: ChatMessageType.voice, voice: voice);

    testWidgets('shows the duration, the speed chip and a 36 px play button', (
      tester,
    ) async {
      await ChatHarness(initial: chatState([voiceMessage()])).pump(tester);
      expect(find.text('0:08'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
      expect(
        tester.getSize(
          find
              .ancestor(
                of: find.byIcon(LucideIcons.play),
                matching: find.byType(Container),
              )
              .first,
        ),
        const Size(36, 36),
      );
      final waveform = tester.getSize(find.byType(Waveform));
      expect(waveform.width, 32 * 3 + 31 * 2);
    });

    testWidgets(
      'play starts the clip at the chosen speed; speed cycles 1× → 1,5× → 2× → 1×',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final harness = ChatHarness(
          initial: chatState([voiceMessage(sender: other)]),
        );
        await harness.pump(tester);
        await tester.tap(find.bySemanticsLabel('Lire le message vocal'));
        await tester.pump();
        expect(harness.player.played.single.url, voice.url);

        await tester.tap(find.text('1×'));
        await tester.pump();
        expect(find.text('1,5×'), findsOneWidget);
        expect(harness.player.speeds, [1.5]);
        await tester.tap(find.text('1,5×'));
        await tester.pump();
        expect(find.text('2×'), findsOneWidget);
        await tester.tap(find.text('2×'));
        await tester.pump();
        expect(find.text('1×'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'while it plays: pause button, elapsed time; tapping again pauses',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final harness = ChatHarness(initial: chatState([voiceMessage()]));
        await harness.pump(tester);
        await tester.tap(find.bySemanticsLabel('Lire le message vocal'));
        await tester.pump();
        harness.player.positionController.add(const Duration(seconds: 4));
        // One pump delivers the stream event, the next one draws it.
        await tester.pump();
        await tester.pump();
        expect(find.text('0:04'), findsOneWidget);
        expect(find.bySemanticsLabel('Mettre en pause'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Mettre en pause'));
        await tester.pump();
        expect(harness.player.pauses, 1);
        semantics.dispose();
      },
    );

    testWidgets('another clip playing does not move this one', (tester) async {
      final harness = ChatHarness(initial: chatState([voiceMessage()]));
      await harness.pump(tester);
      await harness.player.play('https://elsewhere.example.com/other.m4a');
      harness.player.positionController.add(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('0:08'), findsOneWidget);
    });

    testWidgets(
      'a clip that cannot play (expired URL) says so and reloads the thread',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final harness = ChatHarness(initial: chatState([voiceMessage()]));
        harness.player.failNextPlay = true;
        await harness.pump(tester);
        final loadsBefore = harness.actions.loadCalls;
        await tester.tap(find.bySemanticsLabel('Lire le message vocal'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Lecture impossible'), findsOneWidget);
        expect(harness.actions.loadCalls, loadsBefore + 1);
        semantics.dispose();
      },
    );

    test('the 48 recorded values are squeezed to 32 bars', () {
      final bars = Waveform.resample(
        List.generate(48, (i) => i < 24 ? 0 : 100),
      );
      expect(bars, hasLength(32));
      expect(bars.first, 0);
      expect(bars.last, 1);
      expect(Waveform.resample(const []), hasLength(32));
    });

    test('speed labels use the French decimal comma', () {
      expect(VoiceBubbleContent.speedLabel(1.5), '1,5×');
      expect(VoiceBubbleContent.speedLabel(2), '2×');
    });
  });

  group('link preview', () {
    final link = LinkPreview(
      url: 'https://www.example.org/article',
      title: 'Un très bon article sur Shabbat',
      siteName: 'Example',
      imageUrl: tinyPngUri,
    );

    testWidgets(
      'title and domain under the text; tapping opens the link outside the app',
      (tester) async {
        final m = msg(
          1,
          other,
          'Regardez ça https://www.example.org/article',
          linkPreview: link,
        );
        final harness = ChatHarness(initial: chatState([m]));
        await harness.pump(tester);
        expect(find.text('Un très bon article sur Shabbat'), findsOneWidget);
        expect(find.text('example.org'), findsOneWidget);
        await tester.tap(find.text('Un très bon article sur Shabbat'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(harness.opened, [Uri.parse('https://www.example.org/article')]);
      },
    );

    testWidgets('without an image the card shows a neutral tint, no icon', (
      tester,
    ) async {
      final m = msg(
        1,
        other,
        'Voir',
        linkPreview: LinkPreview(url: 'https://example.org/x', title: 'Titre'),
      );
      await ChatHarness(initial: chatState([m])).pump(tester);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });
}
