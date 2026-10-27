import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/verification_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/verification/providers/verification_providers.dart';
import 'package:mazl/presentation/features/verification/screens/verification_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../verification/verification_screen_test.dart'
    show FakeCapture, FakeVerificationApi;
import 'duo_geometry.dart';

// The page « Vérification » in every state, in every pose of the foldable
// iPhone (iPhone Duo): the sweep of all_screens_duo_test.dart only sees the
// state the demo server gives (nothing verified).

class _Failing extends FakeVerificationApi {
  @override
  Future<ApiResponse<VerificationStatus>> getStatus() async =>
      ApiResponse.failure('network', ApiErrorKind.network);
}

class _NeverLoads extends FakeVerificationApi {
  @override
  Future<ApiResponse<VerificationStatus>> getStatus() =>
      Completer<ApiResponse<VerificationStatus>>().future;
}

class _Hanging implements LivenessCapture {
  @override
  Future<List<Uint8List>?> capture(
    BuildContext context,
    List<FaceChallenge> challenges,
  ) => Completer<List<Uint8List>?>().future;
}

VerificationStatus _status({
  bool photo = false,
  bool identity = false,
  DateTime? next,
}) => VerificationStatus.fromJson({
  'photo': {
    'verified': photo,
    'verified_at': photo ? '2026-10-26T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'identity': {
    'verified': identity,
    'verified_at': identity ? '2026-10-26T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'level': identity ? 'identity' : (photo ? 'photo' : 'none'),
  'is_verified': photo || identity,
  'next_attempt_time': next?.toUtc().toIso8601String(),
});

class _Case {
  const _Case(
    this.name,
    this.api, {
    this.capture,
    this.afterOpen,
    this.mainAction = true,
  });

  final String name;
  final FakeVerificationApi Function() api;
  final LivenessCapture Function()? capture;
  final Future<void> Function(WidgetTester tester)? afterOpen;

  /// The page has a filled button that must be in view without scrolling.
  final bool mainAction;
}

final _cases = <_Case>[
  _Case('nothing verified', () => FakeVerificationApi(statuses: [_status()])),
  _Case(
    'level 1 only',
    () => FakeVerificationApi(statuses: [_status(photo: true)]),
  ),
  _Case(
    'both verified',
    () => FakeVerificationApi(statuses: [_status(photo: true, identity: true)]),
    mainAction: false,
  ),
  _Case(
    'limit reached',
    () => FakeVerificationApi(
      statuses: [_status(next: DateTime.now().add(const Duration(hours: 5)))],
    ),
  ),
  _Case(
    'refused',
    () => FakeVerificationApi(statuses: [_status()])
      ..outcome = ApiResponse.success(
        const VerificationOutcome(verified: false, reason: 'profile_mismatch'),
      ),
    afterOpen: (tester) async {
      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pumpAndSettle();
    },
  ),
  _Case(
    'in progress',
    () => FakeVerificationApi(statuses: [_status()]),
    capture: _Hanging.new,
    afterOpen: (tester) async {
      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    },
  ),
  _Case('error', _Failing.new, mainAction: false),
  _Case('loading', _NeverLoads.new, mainAction: false),
];

void main() {
  setUpAll(loadAppFonts);

  for (final testCase in _cases) {
    for (final pose in DuoPose.values) {
      testWidgets('verification, ${testCase.name}, in ${pose.name}', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await _check(tester, testCase, pose);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}

Future<void> _check(WidgetTester tester, _Case testCase, DuoPose pose) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        verificationApiProvider.overrideWithValue(testCase.api()),
        livenessCaptureProvider.overrideWithValue(
          testCase.capture?.call() ?? FakeCapture(null),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        builder: duoAppBuilder(controller),
        home: const VerificationScreen(),
      ),
    ),
  );
  // The loading state never settles: a few frames are enough.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  await testCase.afterOpen?.call(tester);
  await settleFold(tester);

  expect(
    tester.takeException(),
    isNull,
    reason: '${testCase.name} in ${pose.name}',
  );
  final problems = [
    ...tappableProblems(tester, pose),
    ...foldCrossingProblems(tester, pose),
    ...navigationOutsideColumnProblems(tester, pose),
  ];
  if (testCase.mainAction) {
    final main = find.byType(ElevatedButton);
    expect(main, findsWidgets);
    final notInView = primaryProblem(tester, pose, main.first);
    if (notInView != null) problems.add(notInView);
  }
  expect(problems, isEmpty, reason: '${testCase.name} in ${pose.name}');

  if (await scrollListsToTheEnd(tester)) {
    final atTheEnd = [
      ...tappableProblems(tester, pose),
      ...foldCrossingProblems(tester, pose),
    ];
    expect(
      atTheEnd,
      isEmpty,
      reason: '${testCase.name} in ${pose.name}, scrolled to the end',
    );
  }
}
