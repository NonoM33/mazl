import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/visitors/screens/visitors_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _FakeVisitorsApi implements ApiService {
  _FakeVisitorsApi(this.result);

  final ApiResponse<VisitorsData> result;

  @override
  Future<ApiResponse<VisitorsData>> getProfileVisitors() async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeVisitorsApi: ${invocation.memberName}');
}

ProfileVisitor _visitor(int id, Duration ago) => ProfileVisitor(
  userId: id,
  displayName: 'Jeanne$id',
  age: 20 + id,
  visitedAt: DateTime.now().subtract(ago),
);

VisitorsData _data({bool premium = true, bool empty = false}) => VisitorsData(
  isPremium: premium,
  totalCount: empty ? 0 : 5,
  visitors: empty
      ? []
      : [
          _visitor(1, const Duration(minutes: 5)),
          _visitor(2, const Duration(hours: 3, minutes: 5)),
          _visitor(3, const Duration(hours: 30)),
          _visitor(4, const Duration(days: 3, hours: 2)),
          _visitor(5, const Duration(days: 15)),
        ],
);

Future<void> _pump(
  WidgetTester tester,
  ApiResponse<VisitorsData> result,
  L10nCase c,
) async {
  await pumpLocalized(
    tester,
    VisitorsScreen(apiService: _FakeVisitorsApi(result)),
    locale: c.locale,
    brightness: c.brightness,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

const _frenchTexts = [
  'Qui a visité mon profil',
  '5 visites',
  '5 cette semaine',
  'Il y a 5 min',
  'Il y a 3h',
  'Hier',
  'Il y a 3 jours',
  'Il y a 2 sem.',
  'Découvrez qui vous a visité',
  'Passez à mazl+ pour voir les profils',
  'Pas encore de visiteurs',
  'Activer un Boost',
];

void main() {
  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(
      tester,
      VisitorsScreen(
        apiService: _FakeVisitorsApi(ApiResponse.success(_data())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Qui a visité mon profil'), findsOneWidget);
    expect(find.text('5 visites'), findsOneWidget);
    expect(find.text('Il y a 5 min'), findsOneWidget);
    expect(find.text('Il y a 3h'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Il y a 3 jours'), findsOneWidget);
    expect(find.text('Il y a 2 sem.'), findsOneWidget);
  });

  testWidgets('English premium member', (tester) async {
    await _pump(tester, ApiResponse.success(_data()), l10nCases.first);
    expect(find.text('Who visited my profile'), findsOneWidget);
    expect(find.text('5 visits'), findsOneWidget);
    expect(find.text('4 this week'), findsOneWidget);
    expect(find.text('5 min ago'), findsOneWidget);
    expect(find.text('3h ago'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('3 days ago'), findsOneWidget);
    expect(find.text('2 wk ago'), findsOneWidget);
  });

  testWidgets('Russian picks plural forms', (tester) async {
    await _pump(
      tester,
      ApiResponse.success(_data()),
      const L10nCase(Locale('ru'), Brightness.light),
    );
    expect(find.text('5 визитов'), findsOneWidget);
    expect(find.text('3 дня назад'), findsOneWidget);
  });

  testWidgets('Hebrew uses the dual for two visits', (tester) async {
    await _pump(
      tester,
      ApiResponse.success(
        VisitorsData(
          isPremium: true,
          totalCount: 2,
          visitors: [_visitor(1, const Duration(minutes: 5))],
        ),
      ),
      const L10nCase(Locale('he'), Brightness.light),
    );
    expect(find.text('שני ביקורים'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('premium member in ${c.name}', (tester) async {
      await _pump(tester, ApiResponse.success(_data()), c);
      expectNoFrench(_frenchTexts);
      expect(
        find.text('NEW'),
        c.locale.languageCode == 'en' ? findsNWidgets(2) : findsNothing,
      );
      expectDirection(tester, find.byType(AppBar), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('free member in ${c.name}', (tester) async {
      await _pump(tester, ApiResponse.success(_data(premium: false)), c);
      expectNoFrench(_frenchTexts);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no visitor yet in ${c.name}', (tester) async {
      await _pump(tester, ApiResponse.success(_data(empty: true)), c);
      expectNoFrench([
        'Pas encore de visiteurs',
        'Complétez votre profil et utilisez un Boost pour attirer plus de visiteurs.',
        'Activer un Boost',
        '0 visite',
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed load in ${c.name} hides the diagnostic', (
      tester,
    ) async {
      await _pump(
        tester,
        ApiResponse.failure('Failed to get visitors', ApiErrorKind.network),
        c,
      );
      expect(find.text('Failed to get visitors'), findsNothing);
      expectNoFrench([
        'Réessayer',
        'Pas de connexion. Vérifiez votre réseau et réessayez.',
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English failed load', (tester) async {
    await _pump(
      tester,
      ApiResponse.failure('Failed to get visitors', ApiErrorKind.network),
      l10nCases.first,
    );
    expect(
      find.text('No connection. Check your network and try again.'),
      findsOneWidget,
    );
  });
}
