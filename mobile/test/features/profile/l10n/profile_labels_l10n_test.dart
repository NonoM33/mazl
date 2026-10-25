import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/compatibility_score.dart';
import 'package:mazl/core/models/profile_labels.dart';
import 'package:mazl/core/models/profile_prompt.dart';
import 'package:mazl/core/models/relationship_intention.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/profile/l10n/compatibility_labels.dart';
import 'package:mazl/presentation/features/profile/l10n/profile_answer_labels.dart';
import 'package:mazl/presentation/features/profile/l10n/prompt_labels.dart';

const _locales = ['fr', 'en', 'he', 'es', 'ru'];

Map<String, String> _fragment(String language) {
  final raw =
      jsonDecode(
            File(
              'lib/l10n/fragments/profile/app_$language.arb',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return {
    for (final entry in raw.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
  };
}

/// Ce que l'écran affiche d'un message ICU, sans ses sélecteurs ni ses {paramètres}.
String _visibleText(String message) => message
    .replaceAll(RegExp(r'\{[A-Za-z]+, plural,'), '')
    .replaceAll(RegExp(r'(=\d+|zero|one|two|few|many|other)\{'), '')
    .replaceAll(RegExp(r'\{[A-Za-z]+\}'), '');

void main() {
  group('chaque valeur de chaque type a un libellé dans les cinq langues', () {
    for (final code in _locales) {
      test(code, () {
        final l10n = lookupAppLocalizations(Locale(code));
        final labels = <String>[
          for (final v in Denomination.values) v.label(l10n),
          for (final v in Kashrut.values) ...[
            v.label(l10n),
            v.optionLabel(l10n),
          ],
          for (final v in ShabbatObservance.values) ...[
            v.label(l10n),
            v.optionLabel(l10n),
          ],
          for (final v in SynagogueVisits.values) v.label(l10n),
          for (final v in RelationshipIntention.values) ...[
            v.label(l10n),
            v.selectorLabel(l10n),
            v.description(l10n),
          ],
          for (final v in PromptQuestion.values) v.text(l10n),
          for (final v in PromptCategory.values) v.label(l10n),
          for (final v in CompatibilityLevel.values) v.label(l10n),
          for (final v in CompatibilityFactorKind.values) v.label(l10n),
          for (final v in CompatibilityVerdict.values) v.label(l10n),
        ];
        expect(labels.where((l) => l.trim().isEmpty), isEmpty);
        expect(
          labels.where((l) => l.contains('_') || l.contains('{')),
          isEmpty,
        );
      });
    }
  });

  group('les valeurs de l\'API deviennent des libellés dans la langue', () {
    test('hébreu et russe', () {
      final he = lookupAppLocalizations(const Locale('he'));
      final ru = lookupAppLocalizations(const Locale('ru'));
      expect(denominationFact(he, 'Laique'), 'חילוני');
      expect(kashrutFact(he, 'kasher_a_la_maison'), 'כשר בבית');
      expect(shabbatFact(he, 'Tres observant'), 'שמירת שבת קפדנית');
      expect(intentionFact(he, 'serious'), 'זוגיות רצינית');
      expect(denominationFact(ru, 'Habad'), 'Хабад');
      expect(kashrutFact(ru, 'Glatt'), 'Глатт кошер');
    });

    test(
      '« Non » et « Autre » : pas de puce, mais une réponse dans la modification',
      () {
        final en = lookupAppLocalizations(const Locale('en'));
        expect(kashrutFact(en, 'Non'), isNull);
        expect(denominationFact(en, 'Autre'), isNull);
        expect(kashrutField(en, 'Non'), 'No');
        expect(denominationField(en, 'Autre'), 'Other');
        expect(shabbatField(en, null), 'Not specified');
      },
    );

    test('une valeur inconnue reste lisible, dans toutes les langues', () {
      for (final code in _locales) {
        final l10n = lookupAppLocalizations(Locale(code));
        expect(
          denominationFact(l10n, 'reconstructionist_jew'),
          'Reconstructionist jew',
        );
      }
    });

    test(
      'les choix de l\'inscription (« Relation serieuse ») sont reconnus',
      () {
        final en = lookupAppLocalizations(const Locale('en'));
        expect(intentionFact(en, 'Relation serieuse'), 'Serious relationship');
        expect(intentionFact(en, 'Mariage'), 'Marriage');
        expect(intentionFact(en, 'Je ne sais pas'), "I don't know yet");
      },
    );
  });

  group(
    'questions de profil : traduites par identifiant, jamais par le texte du serveur',
    () {
      test('les vingt identifiants du serveur sont connus', () {
        const serverIds = [
          'perfect_sunday',
          'fun_fact',
          'life_goal',
          'pet_peeve',
          'proud_of',
          'looking_for',
          'ideal_vacation',
          'favorite_food',
          'hidden_talent',
          'binge_watching',
          'shabbat_ideal',
          'family_tradition',
          'favorite_holiday',
          'friday_night',
          'israel_memory',
          'jewish_value',
          'debate_me',
          'teach_me',
          'together_we_could',
          'first_date',
        ];
        expect(PromptQuestion.values.map((q) => q.id).toList(), serverIds);
        final en = lookupAppLocalizations(const Locale('en'));
        for (final id in serverIds) {
          expect(
            promptQuestionText(en, id, 'texte du serveur'),
            isNot('texte du serveur'),
            reason: id,
          );
        }
      });

      test('un identifiant inconnu garde le texte du serveur', () {
        final en = lookupAppLocalizations(const Locale('en'));
        expect(
          promptQuestionText(en, 'une_question_future', 'Texte du serveur'),
          'Texte du serveur',
        );
      });

      test('un groupe inconnu se range sous « Autre »', () {
        final en = lookupAppLocalizations(const Locale('en'));
        expect(promptCategoryText(en, null), 'Other');
        expect(promptCategoryText(en, 'jewish'), 'Judaism');
      });
    },
  );

  group(
    'aucun reste de français ni de mots latins dans les écritures non latines',
    () {
      for (final code in ['he', 'ru']) {
        test(code, () {
          final fr = _fragment('fr');
          final strays = <String>[];
          for (final entry in _fragment(code).entries) {
            final visible = _visibleText(entry.value);
            final latin = RegExp(
              r'[A-Za-zÀ-ÿ]+',
            ).allMatches(visible).map((m) => m.group(0)!);
            // Le nom de marque reste tels quels, comme les
            // lettres d'un format de date (JJ/MM/AAAA se note DD.MM.YYYY en hébreu).
            final allowed = {'mazl', 'DD', 'MM', 'YYYY'};
            if (latin.any((w) => !allowed.contains(w))) {
              strays.add('${entry.key} : ${entry.value}');
            }
            expect(fr[entry.key], isNotNull, reason: entry.key);
          }
          expect(strays, isEmpty, reason: strays.join('\n'));
        });
      }
    },
  );
}
