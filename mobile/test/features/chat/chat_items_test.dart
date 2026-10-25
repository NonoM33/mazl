import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/chat/logic/chat_dates.dart';
import 'package:mazl/presentation/features/chat/logic/chat_items.dart';

import 'chat_test_support.dart';

List<MessageItem> _messages(List<ChatItem> items) =>
    items.whereType<MessageItem>().toList();

void main() {
  group('grouping (docs/design/CHAT.md §2)', () {
    test(
      'same sender within 3 minutes is one group; the third minute splits it',
      () {
        final items = _messages(
          buildChatItems(
            chatState([
              msg(1, me, 'a', at: today(10, 0)),
              msg(2, me, 'b', at: today(10, 2)),
              msg(3, me, 'c', at: today(10, 5)),
            ]),
          ),
        );
        expect(
          [for (final i in items) (i.first, i.last)],
          [(true, false), (false, true), (true, true)],
        );
      },
    );

    test('another sender always starts a new group', () {
      final items = _messages(
        buildChatItems(
          chatState([
            msg(1, me, 'a', at: today(10, 0)),
            msg(2, other, 'b', at: today(10, 0)),
          ]),
        ),
      );
      expect(
        [for (final i in items) (i.first, i.last)],
        [(true, true), (true, true)],
      );
    });

    test('a group never crosses midnight', () {
      // Calendar arithmetic, not 24 hours: on a daylight saving day,
      // today 23:59 minus 24 h is still today.
      final now = today(23, 59);
      final yesterday = DateTime(now.year, now.month, now.day - 1, 23, 59);
      final items = _messages(
        buildChatItems(
          chatState([
            msg(1, me, 'a', at: yesterday),
            msg(2, me, 'b', at: yesterday.add(const Duration(minutes: 2))),
          ]),
        ),
      );
      expect(items[0].last, isTrue);
      expect(items[1].first, isTrue);
    });
  });

  group('separators and markers', () {
    test('one date row per day, before its first message', () {
      final yesterday = today(12, 0).subtract(const Duration(days: 1));
      final items = buildChatItems(
        chatState([
          msg(1, me, 'a', at: yesterday),
          msg(2, other, 'b', at: today(9, 0)),
          msg(3, me, 'c', at: today(9, 1)),
        ], hasMore: true),
      );
      expect(items.map((i) => i.runtimeType.toString()), [
        'DateItem',
        'MessageItem',
        'DateItem',
        'MessageItem',
        'MessageItem',
      ]);
    });

    test('when nothing older exists the first day becomes « Match »', () {
      final items = buildChatItems(
        chatState([msg(1, me, 'a', at: today(9, 0))]),
      );
      expect(items.first, isA<StartItem>());
      expect(items.whereType<DateItem>(), isEmpty);
    });

    test(
      'a spinner tops the list while older messages load, typing closes it',
      () {
        final state = chatState(
          [msg(1, me, 'a')],
          hasMore: true,
          typing: true,
        ).copyWith(loadingOlder: true);
        final items = buildChatItems(state);
        expect(items.first, isA<LoadingOlderItem>());
        expect(items.last, isA<TypingItem>());
      },
    );
  });

  group('« Vu »', () {
    test(
      'only the last sent message that was read carries it, with the read time',
      () {
        final items = _messages(
          buildChatItems(
            chatState([
              msg(1, me, 'a', readAt: today(20, 47)),
              msg(2, me, 'b', readAt: today(20, 47)),
              msg(3, other, 'c'),
              msg(4, me, 'd'),
            ]),
          ),
        );
        expect(
          [for (final i in items) i.seenAt],
          [null, today(20, 47), null, null],
        );
      },
    );

    test('nothing is shown when nothing was read', () {
      final items = _messages(
        buildChatItems(chatState([msg(1, me, 'a'), msg(2, me, 'b')])),
      );
      expect(items.every((i) => i.seenAt == null), isTrue);
    });
  });

  group('date labels', () {
    final now = DateTime(2026, 10, 23, 12);
    late AppLocalizations fr;
    setUpAll(() async {
      await initializeDateFormatting();
      fr = lookupAppLocalizations(const Locale('fr'));
    });
    test('today, yesterday, then weekday and date', () {
      expect(dayLabel(fr, DateTime(2026, 10, 23), now), "Aujourd'hui");
      expect(dayLabel(fr, DateTime(2026, 10, 22), now), 'Hier');
      expect(dayLabel(fr, DateTime(2026, 10, 21), now), 'Mer. 21 oct.');
      expect(dayLabel(fr, DateTime(2025, 12, 31), now), 'Mer. 31 déc. 2025');
    });
    test(
      'clock is zero padded',
      () => expect(clock(fr, DateTime(2026, 1, 1, 9, 5)), '09:05'),
    );
    test(
      'voice duration',
      () => expect(minutesSeconds(const Duration(seconds: 65)), '1:05'),
    );
  });
}
