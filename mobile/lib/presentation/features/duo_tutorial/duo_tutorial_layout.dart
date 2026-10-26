import 'dart:ui';

/// Où se posent la scène 3D et le texte du tutoriel, dans la page (la fenêtre
/// moins ses marges de sécurité). Une fonction pure, pour la tester avec les
/// poses mesurées du Duo.
///
/// - mi-ouvert en livre : la scène d'un côté du pli, le texte et les boutons de
///   l'autre (côté de lecture : à gauche en français, à droite en hébreu) ;
/// - mi-ouvert en portable : la scène au-dessus du pli, le texte et les boutons
///   en dessous, à portée de pouce ;
/// - plat et large (paysage) : côte à côte ; plat et haut : la scène au-dessus.
///
/// Rien d'interactif ne touche le pli (règle d'Apple, comme `FoldAwareSplit`).
class DuoTutorialLayout {
  const DuoTutorialLayout({
    required this.scene,
    required this.text,
    required this.stacked,
  });

  final Rect scene;
  final Rect text;

  /// Le texte est sous la scène (le titre se centre) ; sinon il est à côté.
  final bool stacked;

  /// Les deux volets du pli ont au moins cette taille, sinon la page reste d'un tenant.
  static const minPane = 160.0;

  static DuoTutorialLayout resolve({
    required Size size,
    required Rect? fold,
    required bool rtl,
  }) {
    final page = Offset.zero & size;
    if (fold != null && fold.overlaps(page)) {
      final cut = _cut(page, fold, rtl);
      if (cut != null) return cut;
    }
    if (size.width > size.height * 1.1) {
      final sceneWidth = size.width * 0.55;
      const gap = 16.0;
      final scene = rtl
          ? Rect.fromLTWH(size.width - sceneWidth, 0, sceneWidth, size.height)
          : Rect.fromLTWH(0, 0, sceneWidth, size.height);
      final text = rtl
          ? Rect.fromLTRB(0, 0, size.width - sceneWidth - gap, size.height)
          : Rect.fromLTRB(sceneWidth + gap, 0, size.width, size.height);
      return DuoTutorialLayout(scene: scene, text: text, stacked: false);
    }
    final textHeight = (size.height * 0.4).clamp(240.0, 330.0).toDouble();
    final clamped = textHeight > size.height * 0.6
        ? size.height * 0.6
        : textHeight;
    return DuoTutorialLayout(
      scene: Rect.fromLTRB(0, 0, size.width, size.height - clamped),
      text: Rect.fromLTRB(0, size.height - clamped, size.width, size.height),
      stacked: true,
    );
  }

  static DuoTutorialLayout? _cut(Rect page, Rect fold, bool rtl) {
    final runsAcross = fold.width >= fold.height;
    if (runsAcross) {
      final top = fold.top.clamp(page.top, page.bottom);
      final bottom = fold.bottom.clamp(page.top, page.bottom);
      if (top - page.top < minPane || page.bottom - bottom < minPane) {
        return null;
      }
      return DuoTutorialLayout(
        scene: Rect.fromLTRB(page.left, page.top, page.right, top),
        text: Rect.fromLTRB(page.left, bottom, page.right, page.bottom),
        stacked: true,
      );
    }
    final left = fold.left.clamp(page.left, page.right);
    final right = fold.right.clamp(page.left, page.right);
    if (left - page.left < minPane || page.right - right < minPane) return null;
    final start = Rect.fromLTRB(page.left, page.top, left, page.bottom);
    final end = Rect.fromLTRB(right, page.top, page.right, page.bottom);
    return DuoTutorialLayout(
      scene: rtl ? end : start,
      text: rtl ? start : end,
      stacked: false,
    );
  }
}
