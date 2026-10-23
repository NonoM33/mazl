import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/models/message.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/screens/chat_screen.dart';
import 'package:mazl/presentation/features/chat/screens/conversations_screen.dart';

Message _message({required int sender, String content = 'Shabbat shalom'}) => Message(
      id: 1,
      senderId: sender,
      content: content,
      createdAt: DateTime(2026, 10, 23, 18, 30),
    );

Conversation _conversation({int unread = 0}) => Conversation(
      id: 7,
      matchId: 3,
      lastMessage: 'On se retrouve vendredi ?',
      lastMessageAt: DateTime(2026, 10, 23, 18, 30),
      unreadCount: unread,
      otherUser: ConversationUser(userId: 12, displayName: 'Sarah'),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double safeBottom = 0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, app) => MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: EdgeInsets.only(bottom: safeBottom),
          viewPadding: EdgeInsets.only(bottom: safeBottom),
        ),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

Color? _bubbleColor(WidgetTester tester) {
  final container = tester.widget<Container>(find.byKey(ChatBubble.bubbleKey));
  return (container.decoration! as BoxDecoration).color;
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void _expectNoGradient(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration) {
      expect(decoration.gradient, isNull, reason: 'aucun dégradé dans le design');
    }
  }
}

void main() {
  group('bulle de message', () {
    testWidgets('ma bulle est tekhelet avec un texte blanc', (tester) async {
      await _pump(
        tester,
        ChatBubble(message: _message(sender: 1), isMe: true, formattedTime: '18:30'),
      );
      expect(_bubbleColor(tester), AppColors.tekhelet);
      expect(_textColor(tester, 'Shabbat shalom'), Colors.white);
      _expectNoGradient(tester);
    });

    testWidgets('la bulle de l\'autre est brume avec un texte encre', (tester) async {
      await _pump(
        tester,
        ChatBubble(message: _message(sender: 2), isMe: false, formattedTime: '18:30'),
      );
      expect(_bubbleColor(tester), AppColors.mist);
      expect(_textColor(tester, 'Shabbat shalom'), AppColors.ink);
    });

    testWidgets('le coin de la queue est à 6 et la largeur plafonnée à 270', (tester) async {
      await _pump(
        tester,
        ChatBubble(
          message: _message(sender: 1, content: 'a ' * 200),
          isMe: true,
          formattedTime: '18:30',
        ),
      );
      final container = tester.widget<Container>(find.byKey(ChatBubble.bubbleKey));
      final radius = (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
      expect(radius.bottomRight, const Radius.circular(6));
      expect(radius.bottomLeft, const Radius.circular(22));
      expect(tester.getSize(find.byKey(ChatBubble.bubbleKey)).width, lessThanOrEqualTo(270));
    });
  });

  group('ligne de conversation', () {
    testWidgets('non lue : pastille tekhelet et texte plus marqué', (tester) async {
      await _pump(
        tester,
        ConversationRow(conversation: _conversation(unread: 2), formattedTime: '18:30', onTap: () {}),
      );
      final dot = find.byKey(ConversationRow.unreadDotKey);
      expect(dot, findsOneWidget);
      expect(tester.getSize(dot), const Size(8, 8));
      final decoration = tester.widget<Container>(dot).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.tekhelet);
      final preview = tester.widget<Text>(find.byKey(ConversationRow.previewKey));
      expect(preview.style?.fontWeight, FontWeight.w500);
      expect(preview.style?.color, AppColors.ink);
      expect(tester.getSize(find.byType(ConversationRow)).height, greaterThanOrEqualTo(80));
    });

    testWidgets('lue : ni pastille ni texte marqué', (tester) async {
      await _pump(
        tester,
        ConversationRow(conversation: _conversation(), formattedTime: '18:30', onTap: () {}),
      );
      expect(find.byKey(ConversationRow.unreadDotKey), findsNothing);
      final preview = tester.widget<Text>(find.byKey(ConversationRow.previewKey));
      expect(preview.style?.fontWeight, FontWeight.w400);
      expect(preview.style?.color, AppColors.muted);
      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('18:30'), findsOneWidget);
    });

    testWidgets('un appui déclenche onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ConversationRow(conversation: _conversation(), formattedTime: '18:30', onTap: () => taps++),
      );
      await tester.tap(find.byType(ConversationRow));
      expect(taps, 1);
    });
  });

  group('barre de saisie', () {
    testWidgets('le bouton Envoyer porte son libellé et envoie le texte saisi', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final sent = <String>[];
      await _pump(tester, ChatComposer(controller: controller, onSend: sent.add));

      expect(find.bySemanticsLabel('Envoyer'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Bonjour Sarah  ');
      await tester.tap(find.bySemanticsLabel('Envoyer'));
      await tester.pump();

      expect(sent, ['Bonjour Sarah']);
      semantics.dispose();
    });

    testWidgets('un champ vide n\'envoie rien', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final sent = <String>[];
      await _pump(tester, ChatComposer(controller: controller, onSend: sent.add));
      await tester.tap(find.bySemanticsLabel('Envoyer'));
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('pendant un envoi, le bouton est inactif', (tester) async {
      final controller = TextEditingController(text: 'Salut');
      addTearDown(controller.dispose);
      final sent = <String>[];
      await _pump(tester, ChatComposer(controller: controller, onSend: sent.add, isSending: true));
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('la capsule fait 60 de haut et flotte à 12 px au moins de la zone sûre', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: ChatComposer(controller: controller, onSend: (_) {}),
        ),
        safeBottom: 34,
      );

      final capsule = find.byKey(ChatComposer.capsuleKey);
      expect(tester.getSize(capsule).height, 60);
      expect(tester.getSize(capsule).width, 390 - 32);
      final bottom = tester.getBottomLeft(capsule).dy;
      expect(844 - 34 - bottom, greaterThanOrEqualTo(12));
      expect(844 - bottom, greaterThanOrEqualTo(46));
      _expectNoGradient(tester);
    });
  });
}
