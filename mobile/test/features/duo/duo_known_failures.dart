import '../../helpers/duo_poses.dart';

/// A screen that does not yet fit one pose of the foldable iPhone (iPhone
/// Duo), as measured by `all_screens_duo_test.dart`.
class DuoKnownFailure {
  const DuoKnownFailure(this.screen, this.pose, this.reason);

  /// `DuoScreen.id`.
  final String screen;
  final DuoPose pose;

  /// What the measure found, short.
  final String reason;
}

/// The ratchet. Every couple (screen, pose) that fails TODAY. The test fails
/// when a screen that is not listed fails, and when a listed one passes: the
/// list can only shrink. Fixing a screen means deleting its lines here.
const List<DuoKnownFailure> duoKnownFailures = [
  DuoKnownFailure(
    '/boost',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/chat',
    DuoPose.halfOpenLaptop,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/activities',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/activities/:activityId',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/activities/saved',
    DuoPose.halfOpenLaptop,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/calendar',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/events/:eventId',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/mazel-tov',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/space',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/couple/space/settings',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/events/:eventId',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/matches',
    DuoPose.halfOpenLaptop,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/premium/welcome',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/edit',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/settings',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/settings/computers',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/settings/computers/scan',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/settings/religious-data',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/settings/shabbat',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
  DuoKnownFailure(
    '/profile/verification',
    DuoPose.halfOpenBook,
    'crosses the fold (book layout to do)',
  ),
];
