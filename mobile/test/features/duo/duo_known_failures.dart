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
const List<DuoKnownFailure> duoKnownFailures = [];
