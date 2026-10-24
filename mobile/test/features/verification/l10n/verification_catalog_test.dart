import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/verification/l10n/chip_alert_texts.dart';
import 'package:mazl/presentation/features/verification/verification_reasons.dart';

import '../verification_l10n.dart';

const _codes = ['fr', 'en', 'he', 'es', 'ru'];

/// The server's refusal and error codes (docs/verification/CONTRAT.md §4 and the
/// client side failures of `HttpVerificationApi`).
const _serverCodes = [
  'no_face',
  'multiple_faces',
  'face_too_small',
  'pose_mismatch',
  'duplicate_frames',
  'inconsistent_identity',
  'no_profile_photo',
  'profile_mismatch',
  'daily_limit_reached',
  'session_expired',
  'session_not_found',
  'session_used',
  'wrong_frame_count',
  'invalid_image',
  'app_update_required',
  'chip_data_invalid',
  'chip_signature_invalid',
  'csca_unknown',
  'document_expired',
  'underage',
  'document_already_used',
  'document_banned',
  'document_face_mismatch',
  'timeout',
  'network',
];

Map<String, Object?> _fragment(String code) =>
    jsonDecode(
          File(
            'lib/l10n/fragments/verification/app_$code.arb',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

Iterable<MapEntry<String, String>> _texts(String code) => _fragment(code)
    .entries
    .where((e) => !e.key.startsWith('@'))
    .map((e) => MapEntry(e.key, '${e.value}'));

void main() {
  setUpAll(loadDatePatterns);

  group('la promesse de confidentialité', () {
    test(
      'aucune langue ne promet une durée d\'effacement (jamais « effacé sous 6 h »)',
      () {
        final duration = RegExp(
          r'\b\d+\s*(h|hr|hrs|heures?|hours?|horas?|ч|часа?|часов)\b|\d+\s*(שעות|שעה)|\b(six|seis|шесть)\b',
          caseSensitive: false,
        );
        final problems = <String>[];
        for (final code in _codes) {
          for (final entry in _texts(code)) {
            if (duration.hasMatch(entry.value)) {
              problems.add('$code ${entry.key} : ${entry.value}');
            }
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      },
    );

    test(
      'les trois lignes de ce qui est gardé disent la même chose dans chaque langue',
      () {
        final stored = {
          'fr': 'Jamais enregistrées',
          'en': 'Never stored',
          'he': 'לעולם לא נשמרים',
          'es': 'Nunca se guardan',
          'ru': 'Никогда не сохраняются',
        };
        final kept = {
          'fr': 'Pays, expiration, empreinte anonyme',
          'en': 'Country, expiry, anonymous fingerprint',
          'he': 'מדינה, תפוגה, טביעה אנונימית',
          'es': 'País, caducidad, huella anónima',
          'ru': 'Страна, срок действия, анонимный отпечаток',
        };
        for (final code in _codes) {
          final l10n = l10nFor(code);
          expect(l10n.verificationDoneStoredValue, stored[code], reason: code);
          expect(l10n.verificationDoneKeptValue, kept[code], reason: code);
        }
      },
    );

    test('le texte français de la promesse est celui que Renaud a validé', () {
      final fr = frenchL10n;
      expect(
        fr.verificationIntroPrivacy,
        'Rien n\'est conservé : nous ne gardons que le résultat.',
      );
      expect(
        fr.verificationConsent,
        'Nous comparons votre visage à vos photos. Les images ne sont pas conservées ; '
        'seule une empreinte chiffrée l\'est, supprimable à tout moment.',
      );
      expect(
        fr.verificationLivenessPrivacy,
        'Seul dans le cadre, bien éclairé. Les images ne sont pas conservées.',
      );
      expect(fr.verificationDoneStoredValue, 'Jamais enregistrées');
      expect(
        fr.verificationDoneKeptValue,
        'Pays, expiration, empreinte anonyme',
      );
      expect(fr.verificationDoneProfileValue, 'Date de naissance du document');
    });
  });

  group('feuille système NFC de l\'iPhone', () {
    test('les six phrases existent dans chaque langue', () {
      for (final code in _codes) {
        final alerts = chipAlertTexts(l10nFor(code));
        final all = [
          alerts.approach,
          alerts.authenticating,
          alerts.readingPhoto,
          alerts.readingSignature,
          alerts.done,
          alerts.failure,
        ];
        for (final text in all) {
          expect(text.trim(), isNotEmpty, reason: code);
        }
        expect(all.toSet(), hasLength(all.length), reason: code);
      }
    });

    test('en français, ce sont les phrases d\'origine, mot pour mot', () {
      final alerts = chipAlertTexts(frenchL10n);
      expect(alerts.approach, 'Approchez votre document du haut du téléphone.');
      expect(alerts.authenticating, 'Ne bouge pas. Connexion sécurisée…');
      expect(alerts.readingPhoto, 'Lecture de la photo… 40 %');
      expect(alerts.readingSignature, 'Lecture de la signature… 85 %');
      expect(alerts.done, 'Terminé.');
      expect(alerts.failure, 'La lecture a échoué.');
    });

    test('le pourcentage reste celui de la lecture dans chaque langue', () {
      for (final code in _codes) {
        final alerts = chipAlertTexts(l10nFor(code));
        expect(alerts.readingPhoto, contains('40'), reason: code);
        expect(alerts.readingSignature, contains('85'), reason: code);
      }
    });
  });

  group('refus du serveur', () {
    test(
      'chaque code a sa phrase, dans chaque langue, sans fuite du code brut',
      () {
        for (final code in _codes) {
          final l10n = l10nFor(code);
          final generic = verificationReasonText(l10n, 'something_new');
          for (final serverCode in _serverCodes) {
            final text = verificationReasonText(l10n, serverCode);
            expect(text, isNot(generic), reason: '$code $serverCode');
            expect(text, isNot(contains('_')), reason: '$code $serverCode');
          }
          expect(verificationReasonText(l10n, null), generic, reason: code);
        }
      },
    );

    test(
      'les codes ne changent pas : le français dit la même chose qu\'avant',
      () {
        final fr = frenchL10n;
        expect(
          verificationReasonText(fr, 'no_face'),
          'Aucun visage détecté. Mettez-vous face à la caméra, dans un endroit bien éclairé.',
        );
        expect(
          verificationReasonText(fr, 'underage'),
          'Vous devez avoir au moins 18 ans.',
        );
        expect(
          verificationReasonText(fr, 'timeout'),
          'Connexion impossible. Vérifiez votre réseau et réessayez.',
        );
        expect(
          verificationReasonText(fr, 'network'),
          verificationReasonText(fr, 'timeout'),
        );
        expect(
          verificationReasonText(fr, 'document_banned'),
          'Ce document ne peut pas être utilisé.',
        );
        expect(
          verificationReasonText(fr, 'whatever'),
          'Une erreur est survenue. Réessayez dans un instant.',
        );
      },
    );
  });

  group('pluriels de « photos écartées »', () {
    String note(String code, int count) =>
        l10nFor(code).verificationPhotosMismatch(count);

    test('français, anglais, espagnol : une, plusieurs', () {
      expect(
        note('fr', 1),
        'Une de vos photos ne vous ressemble pas : elle ne compte pas.',
      );
      expect(
        note('fr', 3),
        '3 de vos photos ne vous ressemblent pas : elles ne comptent pas.',
      );
      expect(
        note('en', 1),
        'One of your photos does not look like you: it does not count.',
      );
      expect(
        note('en', 4),
        '4 of your photos do not look like you: they do not count.',
      );
      expect(note('es', 1), 'Una de tus fotos no se parece a ti: no cuenta.');
      expect(note('es', 2), '2 de tus fotos no se parecen a ti: no cuentan.');
    });

    test('hébreu : un, deux, plusieurs', () {
      expect(note('he', 1), 'אחת מהתמונות שלך אינה דומה לך: היא לא נספרת.');
      expect(note('he', 2), 'שתיים מהתמונות שלך אינן דומות לך: הן לא נספרות.');
      expect(note('he', 3), '3 מהתמונות שלך אינן דומות לך: הן לא נספרות.');
    });

    test('russe : un, quelques-unes, beaucoup', () {
      expect(
        note('ru', 1),
        'Одно из Ваших фото не похоже на Вас: оно не учитывается.',
      );
      expect(
        note('ru', 2),
        '2 из Ваших фото не похожи на Вас: они не учитываются.',
      );
      expect(
        note('ru', 5),
        '5 из Ваших фото не похожи на Вас: они не учитываются.',
      );
    });
  });

  group('dates du blocage', () {
    final at = DateTime(2026, 10, 24, 9, 5);

    test('l\'heure et le jour suivent la langue', () {
      expect(
        l10nFor('fr').verificationBlockedToday(at),
        'Limite atteinte, nouvel essai possible à 09:05.',
      );
      expect(
        l10nFor('en').verificationBlockedToday(at),
        'Limit reached, you can try again at 09:05.',
      );
      expect(
        l10nFor('fr').verificationBlockedLater(at, at),
        'Limite atteinte, nouvel essai possible le 24/10 à 09:05.',
      );
      expect(
        l10nFor('en').verificationBlockedLater(at, at),
        'Limit reached, you can try again on 10/24 at 09:05.',
      );
      expect(
        l10nFor('ru').verificationBlockedLater(at, at),
        'Лимит исчерпан, повторить попытку можно 24.10 в 09:05.',
      );
    });

    test(
      'le français garde le jour à deux chiffres, comme le motif d\'avant',
      () {
        final early = DateTime(2026, 1, 5, 7, 3);
        expect(
          l10nFor('fr').verificationBlockedLater(early, early),
          'Limite atteinte, nouvel essai possible le 05/01 à 07:03.',
        );
        expect(
          l10nFor('fr').verificationPhotoVerifiedOn(early),
          'Vérifiée le 05/01/2026.',
        );
        expect(
          l10nFor('fr').verificationIdentityCheckedOn(early),
          'Contrôlée le 05/01/2026.',
        );
      },
    );
  });

  group('termes', () {
    test('MAZL, mazl+ et NFC restent tels quels', () {
      for (final code in _codes) {
        final l10n = l10nFor(code);
        expect(
          l10n.verificationCameraNeededBody,
          contains('MAZL'),
          reason: code,
        );
        expect(l10n.verificationFailureNoNfc, contains('NFC'), reason: code);
        expect(
          l10n.verificationFailureNfcDisabled,
          contains('NFC'),
          reason: code,
        );
      }
    });

    test(
      'en hébreu, les deux lignes de lecture automatique s\'appellent « שורות ה-MRZ »',
      () {
        final he = l10nFor('he');
        expect(he.verificationIntroStep1Detail, contains('שורות ה-MRZ'));
        expect(he.verificationScanHint, contains('שורות ה-MRZ'));
        expect(he.verificationScanFrameSemantics, contains('שורות ה-MRZ'));
      },
    );

    test('l\'étape et la pose se disent « sur » dans chaque langue', () {
      expect(l10nFor('fr').verificationStepLabel(1, 3), 'Étape 1 / 3');
      expect(l10nFor('en').verificationStepLabel(2, 3), 'Step 2 / 3');
      expect(l10nFor('he').verificationStepLabel(1, 3), 'שלב 1 מתוך 3');
      expect(
        l10nFor('he').verificationLivenessPoseCounter(2, 3),
        'תנוחה 2 מתוך 3',
      );
    });
  });

  group('voix', () {
    test(
      'l\'hébreu n\'est jamais accordé au genre : aucun pronom « אתה », « אתם » ou « אתן »',
      () {
        // « את » seul est aussi la marque de l\'objet (« את הפנים ») : on ne peut pas le chercher sans bruit.
        final pronoun = RegExp(r'(^|\s)(אתה|אתם|אתן|הנך|הינך)(\s|[.,:!?]|$)');
        final problems = <String>[];
        for (final entry in _texts('he')) {
          if (pronoun.hasMatch(entry.value)) {
            problems.add('${entry.key} : ${entry.value}');
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      },
    );

    test('le russe s\'adresse à « Вы » avec une majuscule, jamais à « ты »', () {
      final informal = RegExp(
        r'(^|\s)(ты|тебя|тебе|твой|твоя|твои|твою)(\s|[.,:!?]|$)',
        caseSensitive: false,
      );
      final lowerVous = RegExp(
        r'(^|\s)(вы|вас|вам|ваш|ваша|ваши|вашу|вашего|вашей|вашим|вашем|ваших)(\s|[.,:!?]|$)',
      );
      final problems = <String>[];
      for (final entry in _texts('ru')) {
        // « вы » en tête de phrase est correct ; en milieu de phrase il faut la majuscule.
        if (informal.hasMatch(entry.value)) {
          problems.add('${entry.key} : ${entry.value}');
        }
        final inside = entry.value.replaceFirst(RegExp(r'^\S+\s'), ' ');
        if (lowerVous.hasMatch(inside)) {
          problems.add('${entry.key} : ${entry.value}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('l\'espagnol tutoie, jamais « usted »', () {
      final formal = RegExp(
        r'\b(usted|ustedes)\b|\b(su perfil|su documento|sus fotos)\b',
        caseSensitive: false,
      );
      final problems = <String>[];
      for (final entry in _texts('es')) {
        if (formal.hasMatch(entry.value)) {
          problems.add('${entry.key} : ${entry.value}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('les locales sont bien celles de l\'app', () {
      for (final code in _codes) {
        expect(l10nFor(code).localeName, code);
      }
      expect(const Locale('he').languageCode, 'he');
    });
  });
}
