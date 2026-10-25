import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';

import '../../helpers/l10n_helpers.dart';

/// Le bouton calendrier de la liste des événements ne faisait rien (`onPressed:
/// () {}`). Le seul calendrier de l'app est dans le mode couple (`/couple/
/// calendar`), inaccessible à un membre hors couple : le bouton est retiré.
void main() {
  for (final locale in [kTestLocale, const Locale('en')]) {
    testWidgets('${locale.languageCode} : aucun bouton calendrier dans la '
        'barre du haut', (tester) async {
      final semantics = tester.ensureSemantics();
      await http.runWithClient(
        () async {
          await pumpLocalized(tester, const EventsListScreen(), locale: locale);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byType(IconButton),
            ),
            findsNothing,
          );
          expect(find.byIcon(LucideIcons.calendarDays), findsNothing);
          expect(find.bySemanticsLabel('Calendrier'), findsNothing);
          expect(find.bySemanticsLabel('Calendar'), findsNothing);
        },
        () => MockClient(
          (request) async =>
              http.Response(jsonEncode({'success': true, 'events': []}), 200),
        ),
      );
      semantics.dispose();
    });
  }
}
