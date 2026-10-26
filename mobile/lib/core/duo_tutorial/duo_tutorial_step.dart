import 'dart:ui' show Size;

import '../layout/fold_state.dart';

/// Les six étapes du tutoriel de l'iPhone Duo, dans l'ordre. Le NOM de chaque
/// étape est celui que connaît la scène 3D (`STEPS` dans
/// `assets/duo_tutorial/pose_math.js`) : ne pas le renommer d'un côté seul.
///
/// Quatre étapes demandent un geste, que l'on VOIT dans la pose réelle de
/// l'appareil ([isDoneBy]) ; la bienvenue et « C'est parti » n'en demandent pas.
enum DuoTutorialStep {
  /// Appareil fermé : la capsule d'onglets dans la colonne.
  welcome,

  /// « Ouvrez-le » : à plat, la liste et le détail côte à côte.
  open,

  /// « Pliez-le comme un livre » : mi-ouvert, le pli vertical.
  book,

  /// « Posez-le sur la table » : mi-ouvert, le pli horizontal (portable).
  table,

  /// « Debout, comme une tente » : posé en V sur la table, écran extérieur en paysage.
  tent,

  /// « C'est parti ».
  ready;

  /// Vrai quand l'étape attend un geste de l'utilisateur.
  bool get hasGesture => switch (this) {
    welcome || ready => false,
    open || book || table || tent => true,
  };

  bool get isLast => this == ready;

  /// L'étape d'après, `null` après la dernière.
  DuoTutorialStep? get next =>
      isLast ? null : DuoTutorialStep.values[index + 1];

  /// Le geste de l'étape est-il fait, d'après la pose réelle ?
  ///
  /// [fold] vient du système (charnière, pli, colonne de la barre) et [size] est
  /// la fenêtre de l'app : un livre se distingue d'un portable par le sens du
  /// pli, une tente d'un appareil fermé debout par la fenêtre en paysage.
  bool isDoneBy(FoldState fold, Size size) => switch (this) {
    welcome || ready => false,
    open => fold.hinge == HingeStatus.fullyOpen,
    book =>
      fold.hinge == HingeStatus.partiallyOpen &&
          !isTentWindow(fold, size) &&
          foldRunsDownThePage(fold, size),
    table =>
      fold.hinge == HingeStatus.partiallyOpen &&
          !isTentWindow(fold, size) &&
          !foldRunsDownThePage(fold, size),
    tent => isTentWindow(fold, size),
  };
}

/// Au plus cette largeur (points) : la fenêtre de l'écran EXTERNE (environ
/// 466 x 678, ou 678 x 466 tourné). L'écran intérieur mesure 669 pt et plus.
const double kOuterDisplayMaxWidth = 700;

/// La pose tente : posé en V sur la table, l'appareil montre son écran
/// extérieur en paysage. Posé ainsi il est entrouvert, et iOS le rapporte
/// `closed` (valeur mesurée par Device Hub) ou, probablement, `partiallyOpen`
/// avec l'écran extérieur toujours actif : on reconnaît donc la FENÊTRE (paysage,
/// de la taille de l'écran extérieur, aucun pli actif), pas la charnière seule.
bool isTentWindow(FoldState fold, Size size) =>
    (fold.hinge == HingeStatus.closed ||
        fold.hinge == HingeStatus.partiallyOpen) &&
    fold.divisions.isEmpty &&
    size.width > size.height &&
    size.width < kOuterDisplayMaxWidth;

/// Le pli du mi-ouvert court-il de haut en bas de la page (appareil tenu comme
/// un livre) ? Sans pli connu, la fenêtre en paysage fait foi.
bool foldRunsDownThePage(FoldState fold, Size size) {
  final division = fold.activeDivision;
  if (division != null) return division.height > division.width;
  return size.width > size.height;
}
