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
    '/discover/profile/:userId',
    DuoPose.halfOpenBook,
    "élément tapable 'J'aime Rachel' dans le pli",
  ),
  DuoKnownFailure(
    '/filters > after a change',
    DuoPose.halfOpenBook,
    "action principale 'Appliquer les filtres' dans le pli",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.closed,
    "élément tapable 'Pick' sous la barre d'accueil (16 pt) ; élément tapable icône U+e0f2 sous la barre d'accueil (8 pt) ; élément tapable icône U+e176 sous la barre d'accueil (8 pt)",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.tent,
    "élément tapable 'Pick' sous la barre d'accueil (18 pt) (en bas de liste) ; élément tapable icône U+e0f2 sous la barre d'accueil (10 pt) (en bas de liste) ; élément tapable icône U+e176 sous la barre d'accueil (10 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.openPortrait,
    "élément tapable 'Pick' sous la barre d'accueil (18 pt) (en bas de liste) ; élément tapable icône U+e0f2 sous la barre d'accueil (10 pt) (en bas de liste) ; élément tapable icône U+e176 sous la barre d'accueil (10 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.openLandscape,
    "élément tapable 'Pick' sous la barre d'accueil (18 pt) (en bas de liste) ; élément tapable icône U+e0f2 sous la barre d'accueil (10 pt) (en bas de liste) ; élément tapable icône U+e176 sous la barre d'accueil (10 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.halfOpenBook,
    "élément tapable 'Pick' sous la barre d'accueil (18 pt) (en bas de liste) ; élément tapable icône U+e0f2 sous la barre d'accueil (10 pt) (en bas de liste) ; élément tapable icône U+e176 sous la barre d'accueil (10 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.halfOpenLaptop,
    "élément tapable 'Pick' sous la barre d'accueil (18 pt) (en bas de liste) ; élément tapable icône U+e0f2 sous la barre d'accueil (10 pt) (en bas de liste) ; élément tapable icône U+e176 sous la barre d'accueil (10 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/daily-picks',
    DuoPose.splitView,
    "élément tapable 'Pick' sous la barre d'accueil (18 pt) (en bas de liste) ; élément tapable icône U+e0f2 sous la barre d'accueil (10 pt) (en bas de liste) ; élément tapable icône U+e176 sous la barre d'accueil (10 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/boost',
    DuoPose.closed,
    "action principale 'Activer le Boost' sous la barre d'accueil (17 pt)",
  ),
  DuoKnownFailure(
    '/boost',
    DuoPose.tent,
    'action principale hors écran, sous la partie visible de sa liste',
  ),
  DuoKnownFailure(
    '/boost',
    DuoPose.openLandscape,
    "action principale 'Activer le Boost' sous la barre d'accueil (20 pt)",
  ),
  DuoKnownFailure(
    '/boost',
    DuoPose.halfOpenBook,
    "action principale 'Activer le Boost' sous la barre d'accueil (20 pt)",
  ),
  DuoKnownFailure(
    '/boost',
    DuoPose.splitView,
    "action principale 'Activer le Boost' sous la barre d'accueil (20 pt)",
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.closed,
    "élément tapable 'Événement' sous la barre d'accueil (2 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.openPortrait,
    "élément tapable 'Événement' sous la barre d'accueil (2 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.openLandscape,
    "élément tapable 'Événement' sous la barre d'accueil (2 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.halfOpenBook,
    "élément tapable 'Événement' sous la barre d'accueil (2 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.halfOpenLaptop,
    "élément tapable 'Événement' sous la barre d'accueil (2 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/events',
    DuoPose.splitView,
    "élément tapable 'Événement' sous la barre d'accueil (2 pt) (en bas de liste)",
  ),
  DuoKnownFailure(
    '/events/:eventId',
    DuoPose.halfOpenBook,
    "action principale 'S'inscrire - 25 €' dans le pli",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.closed,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.tent,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.openPortrait,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.openLandscape,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.halfOpenBook,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.halfOpenLaptop,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/setup',
    DuoPose.splitView,
    "action principale 'Envoyer la demande' sous la barre d'accueil (10 pt)",
  ),
  DuoKnownFailure(
    '/couple/mazel-tov',
    DuoPose.halfOpenBook,
    "action principale 'Commencer notre aventure' dans le pli",
  ),
  DuoKnownFailure(
    '/couple/activities',
    DuoPose.tent,
    'débordement de 26 pt vers le bas (lib/presentation/features/couple/screens/couple_activities_feed_screen.dart:421)',
  ),
  DuoKnownFailure(
    '/couple/activities',
    DuoPose.halfOpenBook,
    'élément tapable icône U+e060 dans le pli',
  ),
  DuoKnownFailure(
    '/couple/activities/saved',
    DuoPose.halfOpenBook,
    "action principale 'Découvrir des activités' dans le pli",
  ),
  DuoKnownFailure(
    '/couple/activities/:activityId',
    DuoPose.halfOpenBook,
    "action principale 'Réserver' dans le pli",
  ),
  DuoKnownFailure(
    '/couple/events',
    DuoPose.halfOpenBook,
    "élément tapable 'Inscrits (0)' dans le pli",
  ),
  DuoKnownFailure(
    '/couple/events/:eventId',
    DuoPose.halfOpenBook,
    "action principale 'S'inscrire' dans le pli",
  ),
];
