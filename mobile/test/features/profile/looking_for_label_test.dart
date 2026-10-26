import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/l10n/generated/app_localizations_fr.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_view_content.dart';

// Seen on 2026-10-26: the profile read « Je recherche : male », the raw value
// of the server.
void main() {
  final l10n = AppLocalizationsFr();

  test('the server codes read as words', () {
    expect(lookingForLabel(l10n, 'male'), 'Un homme');
    expect(lookingForLabel(l10n, 'female'), 'Une femme');
    expect(lookingForLabel(l10n, ' Female '), 'Une femme');
  });

  test('a sentence the member wrote stays as written', () {
    expect(
      lookingForLabel(l10n, 'Une relation sérieuse.'),
      'Une relation sérieuse.',
    );
  });

  test('no raw code is ever shown', () {
    expect(lookingForLabel(l10n, 'all'), isNull);
    expect(lookingForLabel(l10n, 'serious'), isNull);
    expect(lookingForLabel(l10n, null), isNull);
  });
}
