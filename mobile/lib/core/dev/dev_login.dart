import 'package:flutter/foundation.dart';

/// Unique interrupteur de la connexion fictive (développement local).
///
/// `kDebugMode` est une constante de compilation : elle vaut `false` dans les
/// builds profile et release, si bien que tout le code gardé par cette
/// constante est supprimé de ce qui part sur TestFlight / App Store. Aucun
/// drapeau d'exécution, variable d'environnement ou réglage serveur ne peut
/// l'activer en production.
const bool kDevLoginAvailable = kDebugMode;
