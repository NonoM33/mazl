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
    '/profile/verification',
    DuoPose.halfOpenBook,
    "action principale 'Vérifier ma photo' dans le pli",
  ),
  DuoKnownFailure(
    '/verification/identity',
    DuoPose.halfOpenBook,
    "action principale 'Fermer' dans le pli",
  ),
  DuoKnownFailure(
    '/profile/settings/computers',
    DuoPose.halfOpenBook,
    "action principale 'Connecter un ordinateur' dans le pli",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.closed,
    "action principale 'Continuer · 44,99 €' hors écran, 308 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.tent,
    "action principale 'Continuer · 44,99 €' hors écran, 520 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.openPortrait,
    "action principale 'Continuer · 44,99 €' hors écran, 117 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.openLandscape,
    "action principale 'Continuer · 44,99 €' hors écran, 317 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.halfOpenBook,
    "action principale 'Continuer · 44,99 €' hors écran, 317 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.halfOpenLaptop,
    "action principale 'Continuer · 44,99 €' hors écran, 117 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium',
    DuoPose.splitView,
    "action principale 'Continuer · 44,99 €' hors écran, 317 pt sous le bas de l'écran : il faut défiler",
  ),
  DuoKnownFailure(
    '/premium/welcome',
    DuoPose.halfOpenBook,
    "élément tapable 'Plus tard' dans le pli",
  ),
  DuoKnownFailure(
    '/subscription',
    DuoPose.halfOpenBook,
    "élément tapable 'Restaurer mes achats' dans le pli ; action principale 'Découvrir mazl+' dans le pli",
  ),
];
