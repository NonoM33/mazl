import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/chat/voice.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/widgets/message_composer.dart';
import 'package:mazl/presentation/features/chat/widgets/voice_capture.dart';

import 'chat_test_support.dart';

Finder get _mic => find.byIcon(LucideIcons.mic);
Finder get _send => find.bySemanticsLabel('Envoyer');

/// Presses the mic and keeps the finger down; returns the gesture.
Future<TestGesture> _hold(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(_mic));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  return gesture;
}

int _handles(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderBox>()
    .where(
      (box) =>
          box.hasSize &&
          box.size == const Size(36, 5) &&
          box is RenderDecoratedBox,
    )
    .length;

void main() {
  setUpAll(loadChatFonts);

  group('text', () {
    testWidgets(
      'the mic shows while the field is empty and the send arrow once there is text',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await ChatHarness().pump(tester);
        expect(_mic, findsOneWidget);
        expect(_send, findsNothing);
        await tester.enterText(find.byType(TextField), 'Bonjour');
        await tester.pump(const Duration(milliseconds: 200));
        expect(_send, findsOneWidget);
        expect(_mic, findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'sending trims the text, clears the field and announces typing on both ends',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final harness = ChatHarness();
        await harness.pump(tester);
        await tester.enterText(find.byType(TextField), '  Bonjour Noémie  ');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(_send);
        await tester.pump();
        expect(harness.actions.sentTexts, [
          (text: 'Bonjour Noémie', replyToId: null),
        ]);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(
          harness.actions.calls,
          containsAllInOrder(['typing:true', 'typing:false']),
        );
        semantics.dispose();
      },
    );

    testWidgets('an error from the controller is shown, not swallowed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final harness = ChatHarness()..actions.error = ChatFailure.messageRejected;
      await harness.pump(tester);
      await tester.enterText(find.byType(TextField), 'Salut');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(_send);
      await tester.pump();
      await tester.pump();
      expect(find.text('Message refusé.'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'the field grows to 5 lines, then scrolls; the capsule keeps its radius',
      (tester) async {
        await ChatHarness().pump(tester);
        double capsuleHeight() =>
            tester.getSize(find.byKey(MessageComposer.capsuleKey)).height;
        final one = capsuleHeight();
        await tester.enterText(find.byType(TextField), 'a\nb\nc');
        await tester.pump();
        final three = capsuleHeight();
        await tester.enterText(find.byType(TextField), 'a\nb\nc\nd\ne');
        await tester.pump();
        final five = capsuleHeight();
        await tester.enterText(
          find.byType(TextField),
          'a\nb\nc\nd\ne\nf\ng\nh',
        );
        await tester.pump();
        final eight = capsuleHeight();
        expect(one, 60);
        expect(three, greaterThan(one));
        expect(five, greaterThan(three));
        expect(eight, five);
        final decoration =
            tester
                    .widget<Container>(find.byKey(MessageComposer.capsuleKey))
                    .decoration!
                as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(30));
      },
    );

    testWidgets(
      'floats at least 12 px above the safe area, also while a reply is pending',
      (tester) async {
        await ChatHarness().pump(tester, safeBottom: 34);
        final capsule = tester.getRect(find.byKey(MessageComposer.capsuleKey));
        expect(844 - 34 - capsule.bottom, greaterThanOrEqualTo(12));
      },
    );
  });

  group('attachments', () {
    testWidgets(
      '« + » opens one sheet on the root navigator with a single handle',
      (tester) async {
        await ChatHarness().pump(tester);
        await tester.tap(find.byTooltip('Joindre des photos'));
        await tester.pumpAndSettle();
        expect(find.text('Photos'), findsOneWidget);
        expect(find.text('Appareil photo'), findsOneWidget);
        expect(_handles(tester), 1);
      },
    );

    testWidgets('Photos sends the picked photos as one message', (
      tester,
    ) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      await tester.tap(find.byTooltip('Joindre des photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      expect(harness.actions.sentPhotos, [2]);
    });

    testWidgets('Appareil photo sends the shot', (tester) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      await tester.tap(find.byTooltip('Joindre des photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appareil photo'));
      await tester.pumpAndSettle();
      expect(harness.actions.sentPhotos, [1]);
    });

    testWidgets('cancelling the picker sends nothing', (tester) async {
      final harness = ChatHarness();
      harness.picker.gallery = [];
      await harness.pump(tester);
      await tester.tap(find.byTooltip('Joindre des photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      expect(harness.actions.sentPhotos, isEmpty);
    });
  });

  group('voice', () {
    testWidgets(
      'hold: the composer becomes a recording strip; release sends the note',
      (tester) async {
        final harness = ChatHarness();
        await harness.pump(tester, safeBottom: 34);
        final gesture = await _hold(tester);

        expect(harness.recorder.started, isTrue);
        expect(find.text('‹ Glisser pour annuler'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('0:00'), findsOneWidget);

        harness.recorder.elapsedController.add(const Duration(seconds: 3));
        harness.recorder.levelsController.add(80);
        await tester.pump();
        expect(find.text('0:03'), findsOneWidget);

        await gesture.up();
        await tester.pump();
        await tester.pump();
        expect(harness.recorder.stopped, isTrue);
        expect(harness.actions.sentVoices.single.durationMs, 3000);
        expect(
          harness.actions.sentVoices.single.waveform,
          hasLength(waveformBars),
        );
        expect(
          find.byType(TextField),
          findsOneWidget,
          reason: 'the composer is back',
        );
      },
    );

    testWidgets('slide left past 80 px and release: cancelled, nothing sent', (
      tester,
    ) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(find.text('Relâchez pour annuler'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(harness.recorder.cancelled, isTrue);
      expect(harness.actions.sentVoices, isEmpty);
    });

    testWidgets('a short slide still sends', (tester) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(harness.actions.sentVoices, hasLength(1));
    });

    // A message (snackbar) used to cover the composer for 3 s: nothing could
    // be typed or retried. Same rule as the tab bar: it floats 12 px above.
    testWidgets('a chat message floats above the composer, never over it', (tester) async {
      final harness = ChatHarness();
      await harness.pump(tester, safeBottom: 34);
      await tester.tap(_mic);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The visible block (its Material), not the SnackBar's frame, which
      // spans its margins down to the bottom of the screen.
      final snack = tester.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
      final composer = tester.getRect(find.byType(MessageComposer));
      expect(snack.bottom, lessThanOrEqualTo(composer.top - 12));
      expect(snack.top, greaterThan(0));
    });

    // Regression (simulator, 2026-10-24): holding the mic did nothing at all.
    // The strip waited for the recorder to confirm, and a start that threw
    // stayed cached, so every later press failed silently.
    testWidgets('the strip shows as soon as the finger is down, before the recorder answers', (tester) async {
      final harness = ChatHarness();
      harness.recorder.hang = Completer<bool>();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      expect(find.text('‹ Glisser pour annuler'), findsOneWidget);
      harness.recorder.hang!.complete(true);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('a recorder that throws: readable message, and the next press tries again', (tester) async {
      final harness = ChatHarness();
      harness.recorder.throwOnStarts = 1;
      await harness.pump(tester);
      var gesture = await _hold(tester);
      await tester.pump();
      expect(find.text('Impossible d\'enregistrer pour le moment. Réessayez.'), findsOneWidget);
      expect(find.text('‹ Glisser pour annuler'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();

      gesture = await _hold(tester);
      expect(harness.recorder.startCalls, 2, reason: 'the failed start is not cached');
      expect(find.text('‹ Glisser pour annuler'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(harness.actions.sentVoices, hasLength(1));
    });

    testWidgets('a recorder that never answers gives up after 4 s with a message', (tester) async {
      final harness = ChatHarness();
      harness.recorder.hang = Completer<bool>();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text('Impossible d\'enregistrer pour le moment. Réessayez.'), findsOneWidget);
      expect(find.text('‹ Glisser pour annuler'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('slide up to lock: release keeps recording, the arrow sends', (
      tester,
    ) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(harness.recorder.stopped, isFalse);
      expect(find.byTooltip('Annuler l\'enregistrement'), findsOneWidget);
      expect(harness.actions.sentVoices, isEmpty);

      await tester.tap(find.byIcon(LucideIcons.arrowUp));
      await tester.pump();
      await tester.pump();
      expect(harness.actions.sentVoices, hasLength(1));
    });

    testWidgets('locked, the bin throws the note away', (tester) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.tap(find.byTooltip('Annuler l\'enregistrement'));
      await tester.pump();
      await tester.pump();
      expect(harness.recorder.cancelled, isTrue);
      expect(harness.actions.sentVoices, isEmpty);
    });

    testWidgets('refused microphone: a message, no recording UI', (
      tester,
    ) async {
      final harness = ChatHarness();
      harness.recorder.permission = false;
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(
        find.text(
          'Autorisez le micro dans les réglages pour envoyer un vocal.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Maintenez le micro plus longtemps pour enregistrer.'),
        findsNothing,
      );
      expect(harness.actions.sentVoices, isEmpty);
    });

    testWidgets('too short a note says so and sends nothing', (tester) async {
      final harness = ChatHarness();
      harness.recorder.result = null;
      await harness.pump(tester);
      final gesture = await _hold(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Maintenez le micro plus longtemps pour enregistrer.'),
        findsOneWidget,
      );
      expect(harness.actions.sentVoices, isEmpty);
    });

    testWidgets('a quick tap on the mic explains how to record', (
      tester,
    ) async {
      await ChatHarness().pump(tester);
      await tester.tap(_mic);
      await tester.pump();
      expect(
        find.text('Maintenez le micro pour enregistrer un vocal.'),
        findsOneWidget,
      );
    });

    testWidgets('at 120 s the note is sent by itself', (tester) async {
      final harness = ChatHarness();
      await harness.pump(tester);
      final gesture = await _hold(tester);
      harness.recorder.elapsedController.add(maxVoiceDuration);
      await tester.pump();
      await tester.pump();
      expect(harness.actions.sentVoices, hasLength(1));
      await gesture.up();
      await tester.pump();
      expect(
        harness.actions.sentVoices,
        hasLength(1),
        reason: 'the release must not send a second one',
      );
    });

    testWidgets('the recording strip keeps the 12 px gap above the safe area', (
      tester,
    ) async {
      final harness = ChatHarness();
      await harness.pump(tester, safeBottom: 34);
      final gesture = await _hold(tester);
      final capsule = tester.getRect(find.byKey(MessageComposer.capsuleKey));
      expect(844 - 34 - capsule.bottom, greaterThanOrEqualTo(12));
      await gesture.up();
      await tester.pump();
    });
  });

  blockedTests();

  group('VoiceCapture', () {
    test('keeps the last levels only', () async {
      final recorder = FakeVoiceRecorder();
      final capture = VoiceCapture(recorder);
      await capture.start();
      for (var i = 0; i < 40; i++) {
        recorder.levelsController.add(i);
      }
      await Future<void>.delayed(Duration.zero);
      expect(capture.levels, hasLength(VoiceCapture.visibleLevels));
      expect(capture.levels.last, 39);
      await capture.cancel();
    });

    test('finish before the permission answer waits for it', () async {
      final recorder = FakeVoiceRecorder();
      final capture = VoiceCapture(recorder);
      final started = capture.start();
      final recording = capture.finish();
      expect(await started, VoiceStartResult.started);
      expect(await recording, isNotNull);
    });
  });
}

void blockedTests() {
  group('a blocked conversation', () {
    testWidgets('a refused send disables the composer and says why', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final harness = ChatHarness()
        ..actions.error = ChatFailure.blocked;
      await harness.pump(tester, safeBottom: 34);
      await tester.enterText(find.byType(TextField), 'Salut');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.bySemanticsLabel('Envoyer'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(LucideIcons.mic), findsNothing);
      expect(
        find.text('Vous ne pouvez plus écrire dans cette conversation.'),
        findsOneWidget,
      );
      final capsule = tester.getRect(find.byKey(MessageComposer.capsuleKey));
      expect(844 - 34 - capsule.bottom, greaterThanOrEqualTo(12));
      semantics.dispose();
    });

    testWidgets('a conversation that is gone is read-only too', (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = ChatHarness()
        ..actions.error = ChatFailure.conversationGone;
      await harness.pump(tester);
      await tester.enterText(find.byType(TextField), 'Salut');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.bySemanticsLabel('Envoyer'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      semantics.dispose();
    });
  });
}
