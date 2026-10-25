import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/models/couple_activity.dart';
import 'package:mazl/core/models/couple_event.dart';
import 'package:mazl/presentation/features/couple/l10n/couple_feed_labels.dart';
import 'package:mazl/l10n/generated/app_localizations.dart';

import 'feed_l10n_support.dart';

void main() {
  setUpCoupleFeedTests();

  group('labels', () {
    setUpAll(initializeDateFormatting);

    final fr = lookupAppLocalizations(const Locale('fr'));
    final en = lookupAppLocalizations(kEn);
    final he = lookupAppLocalizations(kHe);
    final ru = lookupAppLocalizations(kRu);

    CoupleActivity activity({
      String category = 'culture',
      int? cents,
      int? minutes,
    }) => CoupleActivity(
      id: 1,
      title: 'A',
      description: '',
      category: category,
      priceCents: cents,
      durationMinutes: minutes,
    );

    CoupleEvent event({String? time, int? cents}) => CoupleEvent(
      id: 1,
      title: 'E',
      description: '',
      eventDate: DateTime(2026, 11, 12),
      eventTime: time,
      priceCents: cents,
    );

    test('a free activity or event says so in each language', () {
      expect(activity().priceLabel(fr), 'Gratuit');
      expect(activity(cents: 0).priceLabel(en), 'Free');
      expect(event().priceLabel(he), 'חינם');
      expect(event(cents: 0).priceLabel(ru), 'Бесплатно');
    });

    test('a price is written the way the language writes it', () {
      expect(activity(cents: 12599).priceLabel(en), '€125');
      expect(activity(cents: 12500).priceLabel(fr), '125 €');
      expect(event(cents: 7500).priceLabel(en), '€75 per couple');
      expect(event(cents: 7500).priceLabel(fr), '75 €/couple');
    });

    test('a duration is written in hours and minutes', () {
      expect(activity(minutes: 45).durationLabel(fr), '45min');
      expect(activity(minutes: 120).durationLabel(fr), '2h');
      expect(activity(minutes: 150).durationLabel(fr), '2h30min');
      expect(activity(minutes: 150).durationLabel(en), '2 h 30 min');
      expect(activity(minutes: 150).durationLabel(ru), '2 ч 30 мин');
      expect(activity().durationLabel(fr), isNull);
    });

    test('the categories are translated and an unknown one is kept', () {
      expect(activity(category: 'wellness').categoryName(fr), 'Bien-être');
      expect(activity(category: 'wellness').categoryName(en), 'Wellness');
      expect(activity(category: 'spiritual').categoryName(he), 'רוחניות');
      expect(activity(category: 'mystery').categoryName(en), 'mystery');
      expect(activityFilterLabel(fr, 'gastronomy'), 'Gastro');
      expect(activityFilterLabel(en, null), 'All');
    });

    test('an event date and time follow the language', () {
      expect(event(time: '19:30:00').whenLabel(fr), 'jeu. 12 nov. · 19:30');
      expect(event(time: '19:30').whenLabel(en), 'Thu, Nov 12 · 7:30 PM');
      expect(event().whenLabel(en), 'Thu, Nov 12');
      expect(event(time: '7pm').timeLabel(en), '7pm');
    });

    test('plurals follow the rules of the language', () {
      expect(ru.coupleFeedEventSpotsLeft(21), 'Остался 21 место');
      expect(en.coupleFeedEventSpotsLeft(1), '1 spot left');
    });
  });
}
