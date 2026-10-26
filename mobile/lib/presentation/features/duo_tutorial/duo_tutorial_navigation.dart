import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';

/// Sort du tutoriel : vers [next] quand le démarrage l'a ouvert, sinon retour
/// d'où l'on vient (les Réglages) ; sans historique, vers Découvrir.
void leaveDuoTutorial(BuildContext context, {String? next}) {
  final router = GoRouter.of(context);
  if (next != null) {
    router.go(next);
  } else if (router.canPop()) {
    router.pop();
  } else {
    router.go(RoutePaths.discover);
  }
}
