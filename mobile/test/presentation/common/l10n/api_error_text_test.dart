import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/l10n/generated/app_localizations_en.dart';
import 'package:mazl/l10n/generated/app_localizations_fr.dart';
import 'package:mazl/presentation/common/l10n/api_error_text.dart';

void main() {
  final fr = AppLocalizationsFr();

  test('chaque type d\'erreur a sa phrase, aucune n\'est vide', () {
    final texts = {
      for (final kind in ApiErrorKind.values) kind: apiErrorText(fr, kind),
    };
    expect(texts.values.every((t) => t.trim().isNotEmpty), isTrue);
  });

  test('401 dit de se reconnecter, 429 de patienter', () {
    expect(apiErrorText(fr, ApiErrorKind.unauthorized), fr.errorSessionExpired);
    expect(apiErrorText(fr, ApiErrorKind.rateLimited), fr.errorRateLimited);
    expect(apiErrorText(fr, ApiErrorKind.timeout), fr.errorTimeout);
    expect(apiErrorText(fr, ApiErrorKind.network), fr.errorNetwork);
  });

  test('sans type connu, la phrase générique', () {
    expect(apiErrorText(fr, null), fr.errorUnknown);
  });

  test('la phrase suit la langue', () {
    expect(
      apiErrorText(AppLocalizationsEn(), ApiErrorKind.tooLarge),
      'File too large.',
    );
  });

  test('apiResponseErrorText lit le type de la réponse', () {
    final response = ApiResponse<void>.failure('Failed', ApiErrorKind.server);
    expect(apiResponseErrorText(fr, response), fr.errorServer);
  });
}
